define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := sl3000-emmc
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc mediatek,mt7981b
  
  # [延续原文] 128MB 物理对齐单位修正
  KERNEL_SIZE := 131072k
  BOARD_ROOTFS_PARTSIZE := 524288
  
  KERNEL := kernel-bin | lzma | fit $$(DEVICE_DTS)
  KERNEL_INITRAMFS := 
  
  # [延续原文] 核心驱动包
  DEVICE_PACKAGES := kmod-mmc kmod-sdhci-mtk kmod-fs-f2fs f2fs-tools f2fsck \
	parted lsblk blkid block-mount kmod-zram zram-swap
  
  IMAGES := sysupgrade.bin
  # [🎯 错误修复] 使用 128M 标准缩写，移除多余空格，确保 Makefile 能够闭合解析
  IMAGE/sysupgrade.bin := append-kernel | pad-to 128M | append-rootfs | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
