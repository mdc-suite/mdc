/* SPDX-License-Identifier: MIT */
#ifndef MDC_USER_H
#define MDC_USER_H
#include <stdint.h>
#include <sys/ioctl.h>
#include "mdc_uapi.h"
static inline int mdc_reg_write(int fd, uint32_t offset, uint32_t value)
{ struct mdc_reg r = {offset, value}; return ioctl(fd, MDC_REG_WRITE, &r); }
static inline int mdc_submit(int fd, uint32_t ch, const void *input, uint32_t bytes)
{
    struct mdc_transfer t = {0}; t.channel=ch; t.length=bytes;
    t.data=(uintptr_t)input; return ioctl(fd, MDC_SUBMIT, &t);
}
static inline int mdc_wait(int fd, uint32_t ch, uint32_t timeout_ms, struct mdc_transfer *result)
{
    struct mdc_transfer t = {0}; int rc;
    t.channel=ch; t.timeout_ms=timeout_ms; rc=ioctl(fd, MDC_WAIT, &t);
    if (result) *result=t;
    return rc;
}
static inline int mdc_fetch(int fd, uint32_t ch, void *output, uint32_t capacity, uint32_t *actual)
{
    struct mdc_transfer t = {0}; int rc;
    t.channel=ch; t.data=(uintptr_t)output; t.length=capacity;
    rc=ioctl(fd, MDC_FETCH, &t); if (!rc && actual) *actual=t.actual;
    return rc;
}
#endif
