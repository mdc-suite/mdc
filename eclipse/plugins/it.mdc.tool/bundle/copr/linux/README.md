# Generated MDC Linux interface — ABI 1

This folder contains Linux driver source, a device-tree overlay source, UAPI/userspace headers, a metadata probe and a generic one-output binary-stream runner. It targets the Step-3 KV260 simple-mode polling hardware with the auxiliary-reset correction. There are no hardware/Tcl changes in Step 4. The initial board target is Ubuntu arm64 with Linux 6.8; build the module against the exact running kernel's configured headers. Source generation does not assert successful module build or board validation.

`accelerator.json` is the shared specification snapshot. `include/mdc_config.h` and `device-tree/pl_mdc.dts` derive channel order, direction, register addresses, output count and mode IDs from that model. `software.json` records the software interface. The device is `/dev/mdc_accel0`, with exclusive-open ownership. The old `/dev/uniss_dma` interface is not supported by this module. Recompile/migrate clients to `mdc_uapi.h` and `mdc_user.h` rather than mixing the ioctl definitions.

## Build on the board

After copying this entire folder to Kria:

```bash
make userspace overlay
make module KDIR=/lib/modules/$(uname -r)/build
```

The build produces `userspace/mdc_probe`, `userspace/mdc_run`, `device-tree/pl_mdc.dtbo`, and `driver/mdc_dma.ko`. It requires a C compiler, make, dtc and matching configured kernel headers. Do not substitute headers for a different kernel release. For a prepared cross-compilation environment, pass `ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KDIR=/path/to/configured/target/kernel` to `make module`, and `CC=aarch64-linux-gnu-gcc` to the userspace target. The generated file extension is `.dts`, not `.dist`; `.dtbo` is the compiled overlay.

## Load with the existing working KV260 deployment flow

Stop the old application and unload its driver before replacing its device overlay. The new overlay owns the control aperture and every DMA register aperture in one node; do not keep the old `pl_acc`/`uniss` DMA device nodes or another DMA driver bound to those addresses. Region reservation rejects competing ownership rather than silently mapping it twice.

Use the known-working board loader to program the corrected Step-3 fabric and establish its clocks/resets. Then apply `device-tree/pl_mdc.dtbo` instead of the old device-description overlay, using that loader's overlay mechanism, and load:

```bash
sudo insmod driver/mdc_dma.ko
sudo ./userspace/mdc_probe
```

The overlay is only the Linux device description: it does not contain a firmware filename, FPGA-manager region, clock-provider references or instructions to program hardware. These belong to the already-working board deployment flow. Do not apply it to unprogrammed or reset-held fabric: an MMIO transaction itself can stall and software polling cannot time out such a bus stall. This initial profile assumes KV260's root has two address cells and two size cells, a direct low-DDR DMA path without a newly introduced IOMMU mapping, and one accelerator instance. The overlay deliberately does not claim `dma-coherent` merely because the port is HPC0.

On shutdown, close clients, unload `mdc_dma`, remove its overlay, then reconfigure the FPGA. Do not reprogram the fabric or remove its clock/reset while the driver is bound. A DMA reset timeout blocks further use; allocations that cannot be proven quiescent are deliberately retained until reboot instead of freeing memory still reachable by DMA.

## Transfer API

All transfer commands carry a channel ID explicitly. `MDC_SUBMIT` carries its byte length before copying MM2S input. It accepts positive multiples of four up to the generated buffer capacity (65,536 bytes by default). S2MM submission passes a zero userspace pointer and arms its destination buffer. The driver uses coherent DMA allocations with a 31-bit mask and checks that the entire allocation lies below `0x80000000`, matching the fabric's DDR_LOW-only map. Allocation can fail when suitable low memory is unavailable; it does not silently use unreachable memory.

The usual sequence is: open; GET_INFO; RESET_ALL; configure output beat counts and mode; submit all output channels; submit all input channels; WAIT on every active channel; FETCH each completed output; close. Queue all streams before waiting so that an input cannot deadlock behind an unarmed consumer. Configuration writes are blocked while transfers are active. `MDC_WAIT` polls completion/error status for 1–60,000 ms and reports the actual received byte count; errors/timeouts reset all DMAs. FETCH is allowed only after successful completion and never copies more than the actual received length. Resetting DMA does not flush/reset the actor network; after an aborted partial job, reload/reset the complete accelerator through the board flow before retrying.

`mdc_user.h` provides `mdc_reg_write`, `mdc_submit`, `mdc_wait` and `mdc_fetch`. On ioctl failure, inspect `errno`; `mdc_wait` also returns captured DMA status in its result when available. `EBUSY` indicates another owner or an active channel; `EINVAL` indicates an invalid request; `ETIMEDOUT` indicates bounded DMA polling expired; `EIO` indicates DMA/state failure. Requests use fixed-width fields and an aligned 64-bit userspace pointer representation, with a compat ioctl handler. Pointer/length fields from the legacy uniss API must not be reused.

REG0 contains mode ID in bits 31:24, counter clear in bit 2 and start in bit 0. Output j's beat count is at byte offset `4*(j+1)`. The software interface restricts finite counts to its own buffer capacity. It does not expose the wrapper's disabled-TLAST sentinel or arbitrary physical-register writes. Modes must be present in the generated mode list; incomplete upstream mode identity needs correction before running jobs.

## Generic test application

For a one-output network:

```bash
sudo ./userspace/mdc_run MODE OUTPUT_BEATS INPUT0.bin [INPUT1.bin ...] OUTPUT.bin
```

Input order follows `accelerator.json`; files contain one little-endian 32-bit word per token, with the token in the low bits. The application validates lengths, queues RX first, queues all TX channels, and verifies the received byte count. It does not infer image dimensions, cropping, per-mode active ports or network-specific token schedules. For your edge example, input 0 is pixels and input 1 is size, but those meanings must be supplied by the application; prepare files and output counts using your existing working edge-detection semantics. PGM/image conversion and automatic semantic-role generation are the next application step. Multi-output networks can use the same driver API but need an application that submits all their outputs; this runner deliberately supports one output only.

`mdc_probe` reads software metadata without starting a transfer; closing the device resets the DMAs. The driver is restricted to one owner, polling mode, 32-bit transport words and a 64-KiB buffer per channel. It does not route interrupts, implement scatter-gather, expose mmap, handle live FPGA reconfiguration or act as an upstream DMAengine provider.

## Technical references

The ABI layout follows the Linux [ioctl interface guidance](https://docs.kernel.org/driver-api/ioctl.html). DMA allocation and memory barriers follow the [DMA API guide](https://docs.kernel.org/core-api/dma-api-howto.html). Register programming follows AMD's [AXI DMA simple-mode flow](https://docs.amd.com/r/en-US/pg021_axi_dma/Direct-Register-Mode-Simple-DMA). These documents support the implementation choices; they do not establish board validation of this generated driver.
