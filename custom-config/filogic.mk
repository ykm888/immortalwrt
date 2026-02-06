define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := Custom-1GB-Edition
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc mediatek,mt7981b mediatek,mt7981
  
  # 保持 128MB 内核分区对齐
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 1073741824
  
  # 强制内核进行 LZMA 压缩，减小基础体积
  KERNEL := kernel-bin | lzma | fit $$(DEVICE_DTS)
  
  DEVICE_PACKAGES := \
	kmod-mmc kmod-sdhci-mtk \
	kmod-mt753x \
	kmod-fs-f2fs f2fs-tools f2fsck \
	kmod-usb3 kmod-usb-dwc3-mtk \
	block-mount blkid lsblk parted
  
  # 💡 修改这里：让系统同时生成 .bin 和 .gz 压缩包
  IMAGES := sysupgrade.bin sysupgrade.bin.gz
  
  # 🚀 打包逻辑：直接对齐并拼装
  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | append-metadata
  
  # 🚀 压缩逻辑：将生成的 bin 进行 gzip 压缩，彻底解决文件过大的问题
  IMAGE/sysupgrade.bin.gz := append-kernel | pad-to 134217728 | append-rootfs | append-metadata | gzip
endef
TARGET_DEVICES += sl3000-emmc
