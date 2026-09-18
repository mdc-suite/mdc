// SPDX-License-Identifier: GPL-2.0
/* MDC simple-mode polling driver. Initial supported kernel: Linux 6.8.
 * Exclusive owner, explicit per-request lengths, no userspace MMIO/mmap.
 * Requires the programmed Step-3 KV260 fabric, clocked and out of reset.
 */
#include "mdc_config.h"
#include "mdc_uapi.h"
#include <linux/compat.h>
#include <linux/dma-mapping.h>
#include <linux/fs.h>
#include <linux/io.h>
#include <linux/iopoll.h>
#include <linux/kref.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/version.h>
#define RESET 4u
#define RUN 1u
#define HALTED 1u
#define IDLE 2u
#define IOC 0x1000u
#define ERRORS 0x4070u
#define ACK_IRQ 0x7000u
struct mdc_channel {
  void __iomem *regs;
  void *buffer;
  dma_addr_t address;
  u32 length, actual;
  bool active, complete, unsafe;
};
struct mdc_device {
  struct miscdevice misc;
  struct device *dev;
  struct mutex lock;
  struct kref refs;
  bool opened, dead, poisoned;
  void __iomem *control;
  struct mdc_channel channel[MDC_CHANNELS];
};
static u32 bank(unsigned int i) {
  return mdc_directions[i] == MDC_MM2S ? 0 : 0x30;
}
/* A timed-out reset must not permit DMA buffers to be freed or reused. */
static int reset_all(struct mdc_device *d) {
  unsigned int i;
  int result = 0;
  for (i = 0; i < MDC_CHANNELS; i++) {
    struct mdc_channel *c = &d->channel[i];
    u32 v, b = bank(i);
    int ret;
    if (!c->regs)
      continue;
    writel(RESET, c->regs + b);
    ret = readl_poll_timeout(c->regs + b, v, !(v & RESET), 10, 100000);
    if (!ret)
      ret = readl_poll_timeout(c->regs + b + 4, v, v & HALTED, 10, 100000);
    c->active = c->complete = false;
    c->actual = c->length = 0;
    c->unsafe = ret != 0;
    if (ret)
      result = ret;
  }
  d->poisoned = result != 0;
  return result;
}
static void release_device(struct kref *ref) {
  struct mdc_device *d = container_of(ref, struct mdc_device, refs);
  put_device(d->dev);
  kfree(d);
}
static int mdc_open(struct inode *inode, struct file *file) {
  struct miscdevice *misc = file->private_data;
  struct mdc_device *d = container_of(misc, struct mdc_device, misc);
  int ret = 0;
  mutex_lock(&d->lock);
  if (d->dead)
    ret = -ENODEV;
  else if (d->opened)
    ret = -EBUSY;
  else if (d->poisoned)
    ret = -EIO;
  else {
    d->opened = true;
    kref_get(&d->refs);
    file->private_data = d;
  }
  mutex_unlock(&d->lock);
  return ret;
}
static int mdc_release(struct inode *inode, struct file *file) {
  struct mdc_device *d = file->private_data;
  mutex_lock(&d->lock);
  if (!d->dead && reset_all(d))
    dev_err(d->dev, "DMA reset failed on close; device blocked\n");
  d->opened = false;
  mutex_unlock(&d->lock);
  kref_put(&d->refs, release_device);
  return 0;
}
static bool any_active(struct mdc_device *d) {
  unsigned int i;
  for (i = 0; i < MDC_CHANNELS; i++)
    if (d->channel[i].active)
      return true;
  return false;
}
static bool valid_control(u32 value) {
  unsigned int i, count = MDC_MODES;
  if (value & 0x00fffffa)
    return false; /* Only mode[31:24], clear[2], start[0]. */
  for (i = 0; i < count; i++)
    if ((value >> 24) == mdc_modes[i])
      return true;
  return false;
}
static long mdc_ioctl_locked(struct mdc_device *d, unsigned int cmd,
                             void __user *arg) {
  struct mdc_transfer t;
  struct mdc_channel *c;
  struct mdc_reg reg;
  u32 v, b;
  int ret;
  if (d->dead)
    return -ENODEV;
  if (cmd == MDC_GET_INFO) {
    struct mdc_info info = {MDC_ABI_VERSION, MDC_CHANNELS, MDC_BUFFER_BYTES,
                            MDC_OUTPUTS};
    return copy_to_user(arg, &info, sizeof(info)) ? -EFAULT : 0;
  }
  if (cmd == MDC_RESET_ALL)
    return reset_all(d);
  if (d->poisoned)
    return -EIO;
  if (cmd == MDC_REG_WRITE || cmd == MDC_REG_READ) {
    if (copy_from_user(&reg, arg, sizeof(reg)))
      return -EFAULT;
    if (reg.offset % 4 || reg.offset > 4 * MDC_OUTPUTS)
      return -EINVAL;
    if (cmd == MDC_REG_READ) {
      reg.value = readl(d->control + reg.offset);
      return copy_to_user(arg, &reg, sizeof(reg)) ? -EFAULT : 0;
    }
    if (any_active(d))
      return -EBUSY;
    if (!reg.offset && !valid_control(reg.value))
      return -EINVAL;
    if (reg.offset && (!reg.value || reg.value > MDC_BUFFER_BYTES / 4))
      return -EINVAL;
    writel(reg.value, d->control + reg.offset);
    return 0;
  }
  if (cmd != MDC_SUBMIT && cmd != MDC_WAIT && cmd != MDC_FETCH)
    return -ENOTTY;
  if (copy_from_user(&t, arg, sizeof(t)))
    return -EFAULT;
  if (t.channel >= MDC_CHANNELS || t.flags || t.status || t.actual)
    return -EINVAL;
  c = &d->channel[t.channel];
  b = bank(t.channel);
  if (cmd == MDC_SUBMIT) {
    if (!t.length || t.length % 4 || t.length > MDC_BUFFER_BYTES ||
        t.timeout_ms)
      return -EINVAL;
    if (c->active)
      return -EBUSY;
    if ((mdc_directions[t.channel] == MDC_MM2S) != !!t.data)
      return -EINVAL;
    if (mdc_directions[t.channel] == MDC_MM2S &&
        copy_from_user(c->buffer, u64_to_user_ptr(t.data), t.length))
      return -EFAULT;
    if (mdc_directions[t.channel] == MDC_S2MM)
      memset(c->buffer, 0, t.length);
    c->complete = false;
    c->length = t.length;
    c->actual = 0;
    writel(ACK_IRQ, c->regs + b + 4);
    writel(RUN, c->regs + b);
    ret = readl_poll_timeout(c->regs + b + 4, v, !(v & HALTED) || (v & ERRORS),
                             10, 100000);
    if (ret || (v & ERRORS)) {
      reset_all(d);
      return ret ? ret : -EIO;
    }
    writel(lower_32_bits(c->address), c->regs + b + 0x18);
    dma_wmb();
    c->active = true;
    writel(t.length,
           c->regs + b + 0x28); /* Length starts transfer, always last. */
    return 0;
  }
  if (cmd == MDC_WAIT) {
    if (t.data || t.length || !t.timeout_ms || t.timeout_ms > 60000)
      return -EINVAL;
    if (!c->active && !c->complete)
      return -EINVAL;
    ret = readl_poll_timeout(c->regs + b + 4, v, (v & IOC) || (v & ERRORS), 50,
                             t.timeout_ms * 1000);
    t.status = v;
    if (ret || (v & ERRORS)) {
      /* Quiesce all streams on error. Timeout does not prove idle. */
      unsigned int i;

      dev_err(d->dev, "WAIT failed: ch=%u ret=%d status=%08x requested=%u\n",
              t.channel, ret, v, c->length);

      dev_err(d->dev, "ACC: CONTROL=%08x OUTPUT_COUNT=%u\n", readl(d->control),
              readl(d->control + 4));

      for (i = 0; i < MDC_CHANNELS; ++i) {
        struct mdc_channel *ch = &d->channel[i];
        u32 off = bank(i);

        dev_err(d->dev,
                "DMA%u: CR=%08x SR=%08x ADDR=%08x LEN=%u requested=%u\n", i,
                readl(ch->regs + off), readl(ch->regs + off + 4),
                readl(ch->regs + off + 0x18), readl(ch->regs + off + 0x28),
                ch->length);
      }
      reset_all(d);
      if (copy_to_user(arg, &t, sizeof(t)))
        return -EFAULT;
      return ret ? ret : -EIO;
    }
    dma_rmb();
    c->actual = mdc_directions[t.channel] == MDC_MM2S
                    ? c->length
                    : readl(c->regs + b + 0x28);
    if (!c->actual || c->actual > c->length || c->actual % 4) {
      reset_all(d);
      return -EIO;
    }
    c->active = false;
    c->complete = true;
    t.actual = c->actual;
    return copy_to_user(arg, &t, sizeof(t)) ? -EFAULT : 0;
  }
  if (mdc_directions[t.channel] != MDC_S2MM || !t.data || t.timeout_ms)
    return -EINVAL;
  if (!c->complete || c->active)
    return -EAGAIN;
  if (t.length < c->actual || t.length > MDC_BUFFER_BYTES)
    return -EINVAL;
  if (copy_to_user(u64_to_user_ptr(t.data), c->buffer, c->actual))
    return -EFAULT;
  t.actual = c->actual;
  return copy_to_user(arg, &t, sizeof(t)) ? -EFAULT : 0;
}
static long mdc_ioctl(struct file *file, unsigned int cmd, unsigned long arg) {
  struct mdc_device *d = file->private_data;
  long ret;
  if (mutex_lock_interruptible(&d->lock))
    return -ERESTARTSYS;
  ret = mdc_ioctl_locked(d, cmd, (void __user *)arg);
  mutex_unlock(&d->lock);
  return ret;
}
static const struct file_operations mdc_fops = {
    .owner = THIS_MODULE,
    .open = mdc_open,
    .release = mdc_release,
    .unlocked_ioctl = mdc_ioctl,
    .compat_ioctl = compat_ptr_ioctl,
    .llseek = no_llseek,
};
static void free_buffers(struct mdc_device *d) {
  unsigned int i;
  for (i = 0; i < MDC_CHANNELS; i++) {
    struct mdc_channel *c = &d->channel[i];
    if (!c->buffer)
      continue;
    if (c->unsafe) {
      /* Deliberately quarantine until reboot; freeing could corrupt memory. */
      dev_err(
          d->dev,
          "Channel %u not quiescent; retaining DMA allocation until reboot\n",
          i);
      continue;
    }
    dma_free_coherent(d->dev, MDC_BUFFER_BYTES, c->buffer, c->address);
    c->buffer = NULL;
  }
}
static int mdc_probe(struct platform_device *pdev) {
  struct mdc_device *d;
  struct resource *r;
  unsigned int i;
  int ret;
  d = kzalloc(sizeof(*d), GFP_KERNEL);
  if (!d)
    return -ENOMEM;
  d->dev = get_device(&pdev->dev);
  mutex_init(&d->lock);
  kref_init(&d->refs);
  /* Hardware maps only low 2 GiB. 31-bit mask is intentionally stricter
   * than the DMA core's 32-bit address register width. */
  ret = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(32));
  if (ret)
    goto fail;
  for (i = 0; i <= MDC_CHANNELS; i++) {
    void __iomem *regs;
    r = platform_get_resource(pdev, IORESOURCE_MEM, i);
    if (!r || r->start != mdc_bases[i] || resource_size(r) != 0x10000) {
      ret = -EINVAL;
      goto fail;
    }
    regs = devm_ioremap_resource(&pdev->dev, r);
    if (IS_ERR(regs)) {
      ret = PTR_ERR(regs);
      goto fail;
    }
    if (!i)
      d->control = regs;
    else
      d->channel[i - 1].regs = regs;
  }
  /* Reset before allocating/publishing buffers; fabric must already be live. */
  ret = reset_all(d);
  if (ret)
    goto fail;
  for (i = 0; i < MDC_CHANNELS; i++) {
    struct mdc_channel *c = &d->channel[i];
    c->buffer =
        dma_alloc_coherent(d->dev, MDC_BUFFER_BYTES, &c->address, GFP_KERNEL);
    if (!c->buffer) {
      ret = -ENOMEM;
      goto fail;
    }
    if ((u64)c->address + MDC_BUFFER_BYTES > 0x80000000ULL) {
      ret = -ERANGE;
      goto fail;
    }
  }
  d->misc.minor = MISC_DYNAMIC_MINOR;
  d->misc.name = "mdc_accel0";
  d->misc.fops = &mdc_fops;
  d->misc.parent = &pdev->dev;
  d->misc.mode = 0600;
  ret = misc_register(&d->misc);
  if (ret)
    goto fail;
  platform_set_drvdata(pdev, d);
  dev_info(&pdev->dev, "MDC ABI %u: %u channels, %u-byte buffers\n",
           MDC_ABI_VERSION, MDC_CHANNELS, MDC_BUFFER_BYTES);
  return 0;
fail:
  free_buffers(d);
  kref_put(&d->refs, release_device);
  return ret;
}
static void mdc_remove_common(struct platform_device *pdev) {
  struct mdc_device *d = platform_get_drvdata(pdev);
  misc_deregister(&d->misc);
  mutex_lock(&d->lock);
  d->dead = true;
  reset_all(d);
  free_buffers(d);
  mutex_unlock(&d->lock);
  kref_put(&d->refs, release_device);
}
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 11, 0)
static void mdc_remove(struct platform_device *pdev) {
  mdc_remove_common(pdev);
}
#else
static int mdc_remove(struct platform_device *pdev) {
  mdc_remove_common(pdev);
  return 0;
}
#endif
static const struct of_device_id mdc_match[] = {
    {.compatible = "mdc,kv260-stream-v1"}, {}};
MODULE_DEVICE_TABLE(of, mdc_match);
static struct platform_driver mdc_driver = {
    .probe = mdc_probe,
    .remove = mdc_remove,
    .driver = {.name = "mdc-dma",
               .of_match_table = mdc_match,
               .suppress_bind_attrs = true},
};
module_platform_driver(mdc_driver);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("MDC generated KV260 simple-mode polling DMA driver, ABI 1");
