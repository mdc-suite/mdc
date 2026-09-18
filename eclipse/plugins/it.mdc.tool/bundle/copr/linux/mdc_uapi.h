/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */
#ifndef MDC_UAPI_H
#define MDC_UAPI_H
#include <linux/types.h>
#include <linux/ioctl.h>
#define MDC_ABI_VERSION 1
#define MDC_MM2S 1
#define MDC_S2MM 0
struct mdc_info { __u32 abi, channels, buffer_bytes, output_ports; };
/* SUBMIT: data is userspace input pointer for MM2S, zero for S2MM.
 * WAIT: timeout_ms=1..60000; returns status and actual bytes.
 * FETCH: length is destination capacity, returns actual bytes.
 * Unused fields and flags must be zero; data is not a physical address. */
struct mdc_transfer {
    __u32 channel, length;
    __aligned_u64 data;
    __u32 timeout_ms, status, actual, flags;
};
struct mdc_reg { __u32 offset, value; };
#define MDC_GET_INFO _IOR('M', 0x40, struct mdc_info)
#define MDC_SUBMIT   _IOW('M', 0x41, struct mdc_transfer)
#define MDC_WAIT     _IOWR('M', 0x42, struct mdc_transfer)
#define MDC_FETCH    _IOWR('M', 0x43, struct mdc_transfer)
#define MDC_REG_WRITE _IOW('M', 0x44, struct mdc_reg)
#define MDC_REG_READ _IOWR('M', 0x45, struct mdc_reg)
#define MDC_RESET_ALL _IO('M', 0x46)
#endif
