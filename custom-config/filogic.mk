define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := Custom-128GB-Edition
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc mediatek,mt7981b mediatek,mt7981
  
  # 🚀 空间策略：内核对齐 128MB，固件定义 1GB 以避开构建溢出
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 1073741824
  
  # 🎯 修复核心：定义 KERNEL 取值逻辑
  KERNEL := kernel-bin | lzma | fit $$(DEVICE_DTS)
  
  # 📦 性能套件：支持 1GB 内存和 eMMC 管理
  DEVICE_PACKAGES := \
	kmod-mmc kmod-sdhci-mtk \
	kmod-mt753x \
	kmod-fs-f2fs f2fs-tools f2fsck \
	kmod-usb3 kmod-usb-dwc3-mtk \
	block-mount blkid lsblk parted \
	kmod-zram zram-swap
  
  IMAGES := sysupgrade.bin sysupgrade.bin.gz
  
  # 🛠️ 稳健流水线：直接物理对齐拼装
  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | append-metadata
  IMAGE/sysupgrade.bin.gz := append-kernel | pad-to 134217728 | append-rootfs | append-metadata | gzip

  # 🛡️ 禁用报错源
  KERNEL_INITRAMFS := 
endef
TARGET_DEVICES += sl3000-emmc
