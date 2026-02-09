define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := sl3000-emmc
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc
  
  # ✅ [延续祖传设置] 128MB 内核与分区对齐
  KERNEL_SIZE := 131072k
  BOARD_ROOTFS_PARTSIZE := 1048576
  
  # ✅ [修正逻辑] 必须加入 dtb 注入，确保 1GB RAM 的 DTS 真正生效
  # 使用 fit 模式是 ImmortalWrt 24.10 最稳健的选择
  KERNEL := kernel-bin | lzma | dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | dtb
  
  # ✅ [延续原文] 存储与文件系统核心包
  DEVICE_PACKAGES := kmod-mmc kmod-sdhci-mtk kmod-fs-f2fs f2fs-tools f2fsck \
	parted lsblk blkid block-mount kmod-zram zram-swap
  
  IMAGES := sysupgrade.bin
  # ✅ [物理修复] 显式指定 metadata 设备名，防止多机型编译混淆
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
