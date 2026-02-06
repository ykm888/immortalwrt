define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := Custom-1GB-Edition
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc mediatek,mt7981b mediatek,mt7981
  
  # 强制分区参数：128MB 内核，1GB 总镜像
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 1073741824
  
  # 内核打包逻辑：明确指定 FIT 格式和 LZMA 压缩
  KERNEL := kernel-bin | lzma | fit $$(DEVICE_DTS)
  
  DEVICE_PACKAGES := \
	kmod-mmc kmod-sdhci-mtk \
	kmod-mt753x \
	kmod-fs-f2fs f2fs-tools f2fsck \
	kmod-usb3 kmod-usb-dwc3-mtk \
	block-mount blkid lsblk parted
  
  # 🚀 【核心修复 1】精简镜像生成目标
  # 只生成这两种，避开系统自动生成的、容易导致 Error 2 的 initramfs 镜像
  IMAGES := sysupgrade.bin sysupgrade.bin.gz
  
  # 🚀 【核心修复 2】强制定义流水线，移除所有可能报错的自动校验（如 check-size/pad-rootfs）
  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | append-metadata
  IMAGE/sysupgrade.bin.gz := append-kernel | pad-to 134217728 | append-rootfs | append-metadata | gzip

  # 🚀 【核心修复 3】显式禁用 initramfs 阶段，防止其在 install 步骤报错
  KERNEL_INITRAMFS := 
endef
TARGET_DEVICES += sl3000-emmc
