# LINUX_DIR is set by Buildroot, but not if running manually
ifeq ($(LINUX_DIR),)
LINUX_DIR := /lib/modules/$(shell uname -r)/build
endif

# BUILD_DIR is set by DKMS, but not if running manually
ifeq ($(BUILD_DIR),)
BUILD_DIR := ./
endif

DTS_OUT_DIR := ./out

obj-m += sharp-drm.o
sharp-drm-objs += src/main.o src/drm_iface.o src/params_iface.o src/ioctl_iface.o
ccflags-y := -g -std=gnu99 -Wno-declaration-after-statement

# Armbian automatically applies `console=tty1`, so don't attempt to override it.
# The sharp-drm fb seems to be assigned to /dev/fb2, so map that to tty1.
# The list of fb's can be inspected with `cat /proc/fb`.
BOOT_ENV_FILE := /boot/armbianEnv.txt
BOOT_EXTRAARGS := extraargs=fbcon=font:VGA8x8 fbcon=map:210
BOOT_USER_OVERLAYS := user_overlays=sharp-drm

.PHONY: all clean install uninstall

all: $(DTS_OUT_DIR)/sharp-drm.dts
	$(MAKE) -C '$(LINUX_DIR)' M='$(shell pwd)'

$(DTS_OUT_DIR)/sharp-drm.dts: ./sharp-drm.dts $(DTS_OUT_DIR)
	cpp -nostdinc -I /usr/src/linux-headers-$(shell uname -r)/include -I include -I arch -undef -x assembler-with-cpp ./sharp-drm.dts $@

$(DTS_OUT_DIR):
	mkdir $(DTS_OUT_DIR)

install_modules:
	$(MAKE) -C '$(LINUX_DIR)' M='$(shell pwd)' modules_install
	# Rebuild dependencies
	depmod -A

# Separate rule to be called from DKMS
install_aux: $(BUILD_DIR)/sharp-drm.dts
	# Compile and install device tree overlay
	# This will automatically place the compiled .dtbo in /boot/overlay-user
	# and append `user_overlays=sharp-drm` to /boot/armbianEnv.txt.
	armbian-add-overlay $(DTS_OUT_DIR)/sharp-drm.dts
	# Add extraargs fbcon configuration line if it wasn't already there
	@grep -qxF '$(BOOT_EXTRAARGS)' $(BOOT_ENV_FILE) \
		|| printf '\n$(BOOT_EXTRAARGS)\n' >> $(BOOT_ENV_FILE)
	# Add auto-load module line if it wasn't already there
	@grep -qxF 'sharp-drm' /etc/modules \
		|| echo 'sharp-drm' >> /etc/modules

install: install_modules install_aux

uninstall:
	# Remove fbcon configuration and create a backup file
	@sed -i.save '/$(BOOT_EXTRAARGS)/d' $(BOOT_ENV_FILE)
	# Remove user overlays and create a backup file
	@sed -i.save '/$(BOOT_USER_OVERLAYS)/d' $(BOOT_ENV_FILE)
	# Remove auto-load module line and create a backup file
	@sed -i.save '/sharp-drm/d' /etc/modules
	# Remove device tree overlay
	@rm -f /boot/overlay-user/sharp-drm.dtbo

clean:
	$(MAKE) -C '$(LINUX_DIR)' M='$(shell pwd)' clean
	rm -rf $(DTS_OUT_DIR)
