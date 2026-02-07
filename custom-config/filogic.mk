define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := sl3000-emmc
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc mediatek,mt7981b
  
  # 🎯 延续修复：128MB 对齐
  KERNEL_SIZE := 131072k
  BOARD_ROOTFS_PARTSIZE := 524288
  
  KERNEL := kernel-bin | lzma | fit $$(DEVICE_DTS)
  KERNEL_INITRAMFS := 
  
  DEVICE_PACKAGES := kmod-mmc kmod-sdhci-mtk kmod-fs-f2fs f2fs-tools f2fsck \
	parted lsblk blkid block-mount kmod-zram zram-swap
  
  IMAGES := sysupgrade.bin
  # 🎯 极限修复：移除所有干扰字符，严格执行物理对齐拼接
  IMAGE/sysupgrade.bin := append-kernel | pad-to 128M | append-rootfs | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
