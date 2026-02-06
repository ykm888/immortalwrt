define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := Custom-1GB-Edition
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  # 兼容性补充：加入不带 b 的兼容项
  SUPPORTED_DEVICES := sl,sl3000-emmc mediatek,mt7981b mediatek,mt7981
  
  # 核心修复：延续 128MB 内核分区设置 (128 * 1024 * 1024)
  KERNEL_SIZE := 134217728
  # 限制总镜像大小，防止溢出 1GB 范围
  IMAGE_SIZE := 1073741824
  
  DEVICE_PACKAGES := \
	kmod-mmc kmod-sdhci-mtk \
	kmod-mt753x \
	kmod-fs-f2fs f2fs-tools f2fsck \
	kmod-usb3 kmod-usb-dwc3-mtk \
	block-mount blkid lsblk parted
  
  IMAGES := sysupgrade.bin
  # 修复打包逻辑：确保 kernel 被 pad 到 128MB，从而让 rootfs 准确落在 DTS 定义的偏移地址
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | pad-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
