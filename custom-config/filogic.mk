DTS_DIR := $(DTS_DIR)/mediatek

define Image/Prepare
	rm -f $(KDIR)/ubi_mark
	echo -ne '\\xde\\xad\\xc0\\xde' > $(KDIR)/ubi_mark
endef

define Build/mt7981-bl31-uboot
	cat $(STAGING_DIR_IMAGE)/*u-boot.fip >> $@
endef

define Build/mt798x-gpt
	cp $@ $@.tmp 2>/dev/null || true
	ptgen -g -o $@.tmp -a 1 -l 1024 \
			-t 0x83 -N ubootenv -r -p 512k@4M \
			-t 0x83 -N factory -r -p 2M@4608k \
			-t 0xef -N fip -r -p 4M@6656k \
				-N recovery -r -p 32M@12M \
		$(if $(findstring emmc,$1), -t 0x2e -N production -p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@64M)
	cat $@.tmp >> $@
	rm $@.tmp
endef

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := ../dts
  SUPPORTED_DEVICES := sl,3000-emmc
  IMAGES := sysupgrade.bin fip.bin
  IMAGE/fip.bin := mt7981-bl31-uboot $(1)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools e2fsprogs f2fsck mkf2fs kmod-zram zram-swap
endef
TARGET_DEVICES += sl_3000-emmc
