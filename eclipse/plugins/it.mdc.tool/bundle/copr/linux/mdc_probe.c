/* SPDX-License-Identifier: MIT */
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include "mdc_user.h"
int main(int argc, char **argv)
{
    struct mdc_info info = {0};
    int fd = open(argc > 1 ? argv[1] : "/dev/mdc_accel0", O_RDWR);
    if (fd < 0) { perror("open"); return 1; }
    if (ioctl(fd, MDC_GET_INFO, &info)) { perror("MDC_GET_INFO"); close(fd); return 1; }
    printf("ABI=%u channels=%u outputs=%u buffer_bytes=%u\n", info.abi, info.channels, info.output_ports, info.buffer_bytes);
    close(fd);
    return info.abi == MDC_ABI_VERSION ? 0 : 1;
}
