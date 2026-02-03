#
# SL3000 Dedicated Image definition
# Target: MediaTek Filogic 820 (MT7981)
# Memory/Storage: 1GB RAM / 1GB eMMC
#

define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := Custom-1GB-Edition
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl3000-emmc
  
  # 分区定义：128M 内核分区 + 1024M 整体镜像大小
  KERNEL_SIZE := 128M
  IMAGE_SIZE := 1024M
  
  # 预装核心驱动：确保 eMMC 能被识别，F2FS 能被挂载
  DEVICE_PACKAGES := \
	kmod-mmc kmod-sdhci-mtk \
	kmod-fs-f2fs f2fs-tools f2fsck \
	kmod-usb3 kmod-usb-dwc3-mtk
  
  # 生成 sysupgrade 镜像逻辑
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | pad-rootfs | check-size
endef

TARGET_DEVICES += sl3000-emmc
