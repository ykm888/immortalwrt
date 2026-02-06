define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := Custom-128GB-Edition
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc mediatek,mt7981b mediatek,mt7981
  
  # 🎯 延续修复：128MB 内核对齐，1GB 固件边界
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 1073741824
  
  # 🎯 延续修复：核心打包宏定义
  KERNEL := kernel-bin | lzma | fit $$(DEVICE_DTS)
  
  # 🚀 释放 128GB 和 1GB RAM 潜力的驱动包
  DEVICE_PACKAGES := \
	kmod-mmc kmod-sdhci-mtk \
	kmod-fs-f2fs f2fs-tools f2fsck \
	parted lsblk blkid block-mount \
	kmod-zram zram-swap
  
  IMAGES := sysupgrade.bin sysupgrade.bin.gz
  
  # 🎯 延续修复：物理拼接流水线
  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | append-metadata
  IMAGE/sysupgrade.bin.gz := append-kernel | pad-to 134217728 | append-rootfs | append-metadata | gzip

  # 🎯 核心补丁：禁用救援包，跳过报错流程
  KERNEL_INITRAMFS := 
endef
TARGET_DEVICES += sl3000-emmc
