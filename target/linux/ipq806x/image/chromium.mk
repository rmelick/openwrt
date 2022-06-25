define Build/cros-gpt
	cp $@ $@.tmp 2>/dev/null || true
	ptgen -o $@.tmp -g \
		-T cros_kernel	-N kernel -p $(CONFIG_TARGET_KERNEL_PARTSIZE)m \
				-N rootfs -p $(CONFIG_TARGET_ROOTFS_PARTSIZE)m
	cat $@.tmp >> $@
	rm $@.tmp
endef

define Build/append-kernel-part
	dd if=$(IMAGE_KERNEL) bs=$(CONFIG_TARGET_KERNEL_PARTSIZE)M conv=sync >> $@
endef

# NB: Chrome OS bootloaders replace the '%U' in command lines with the UUID of
# the kernel partition it chooses to boot from. This gives a flexible way to
# consistently build and sign kernels that always use the subsequent
# (PARTNROFF=1) partition as their rootfs.
define Build/cros-vboot
	$(STAGING_DIR_HOST)/bin/cros-vbutil \
		-k $@ -c "root=PARTUUID=%U/PARTNROFF=1" -o $@.new
	@mv $@.new $@
endef

# TODO review device name, should it be tplink_onhub?  google_onhub_tplink???
# TODO what is DEVICE_DTS?  will this pick up the correct dtb file, or should I hard code it here?
define Device/tplink_onhub
	DEVICE_VENDOR := TP-Link
	DEVICE_MODEL := OnHub TGR1900 (Whirlwind)
	SOC := qcom-ipq8064
	KERNEL_SUFFIX := -fit-zImage.itb.vboot
	KERNEL = kernel-bin | fit none $$(DTS_DIR)/$$(DEVICE_DTS).dtb | cros-vboot
	KERNEL_NAME := zImage
	IMAGES += factory.bin
	IMAGE/factory.bin := cros-gpt | append-kernel-part | append-rootfs
	DEVICE_PACKAGES := partx-utils mkf2fs e2fsprogs \
			   kmod-fs-ext4 kmod-fs-f2fs kmod-google-firmware
endef
TARGET_DEVICES += tplink_onhub
