define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := sl3000-emmc
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc
  
  # ✅ [延续祖传设置] 128MB 内核与分区对齐
  KERNEL_SIZE := 131072k
  BOARD_ROOTFS_PARTSIZE := 1048576
  
  # ✅ [修正逻辑] 显式指定 FIT 生成逻辑，防止 install 阶段找不到 KERNEL
  KERNEL := kernel-bin | lzma
  KERNEL_INITRAMFS := kernel-bin | lzma
  
  # ✅ [延续原文] 存储与文件系统核心包
  DEVICE_PACKAGES := kmod-mmc kmod-sdhci-mtk kmod-fs-f2fs f2fs-tools f2fsck \
	parted lsblk blkid block-mount kmod-zram zram-swap
  
  IMAGES := sysupgrade.bin
  # ✅ [绝杀修复] 移除复杂的 pad-to 逻辑，改用标准的镜像合成宏
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
