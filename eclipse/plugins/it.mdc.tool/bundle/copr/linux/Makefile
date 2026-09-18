# Native build on Kria: make userspace overlay; make module
KDIR ?= /lib/modules/$(shell uname -r)/build
CC ?= cc
DTC ?= dtc
CFLAGS ?= -O2 -Wall -Wextra -Werror -std=c11
.PHONY: all userspace overlay module clean
all: userspace overlay
userspace: userspace/mdc_probe userspace/mdc_run userspace/mdc_test
userspace/%: userspace/%.c include/mdc_user.h include/mdc_uapi.h include/mdc_config.h
	$(CC) $(CFLAGS) -Iinclude $< -o $@
userspace/mdc_test: userspace/mdc_test.c include/mdc_test_config.h include/mdc_user.h include/mdc_uapi.h include/mdc_config.h
	$(CC) $(CFLAGS) -Iinclude $< -o $@
overlay: device-tree/pl_mdc.dtbo
device-tree/pl_mdc.dtbo: device-tree/pl_mdc.dts
	$(DTC) -@ -I dts -O dtb -o $@ $<
module:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/driver modules
clean:
	$(RM) userspace/mdc_probe userspace/mdc_run userspace/mdc_test device-tree/pl_mdc.dtbo
	$(MAKE) -C $(KDIR) M=$(CURDIR)/driver clean
