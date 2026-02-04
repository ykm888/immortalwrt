#
# SL3000 Dedicated Image definition
# Target: MediaTek Filogic 820 (MT7981)
# Memory/Storage: 1GB RAM / 1GB eMMC
#

define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := Custom-1GB-Edition
  DEVICE_DTS := mt7981b-sl3000-emmc
  SUPPORTED_DEVICES := sl3000-emmc mediatek,mt7981b
  
  # 分区逻辑：内核预留 64M，总镜像设为 1000M 留出对齐缓冲
  KERNEL_SIZE := 64M
  IMAGE_SIZE := 1000M
  
  # 旗舰版预装包：包含 eMMC、F2FS 扩容及基础磁盘工具
  DEVICE_PACKAGES := \
	kmod-mmc kmod-sdhci-mtk \
	kmod-fs-f2fs f2fs-tools f2fsck \
	kmod-usb3 kmod-usb-dwc3-mtk \
	block-mount blkid lsblk parted
  
  # 镜像生成逻辑
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | pad-rootfs | check-size
endef

TARGET_DEVICES += sl3000-emmc
