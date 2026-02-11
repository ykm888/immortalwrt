define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 (eMMC)
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc
  
  # ✅ 修正：128MB 内核分区（单位：KB）
  KERNEL_SIZE := 131072k
  # ✅ 修正：1GB 根分区（单位：MB）
  BOARD_ROOTFS_PARTSIZE := 1024
  
  # ✅ 修正：标准内核+DTB合并步骤
  KERNEL := kernel-bin | lzma | append-dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | append-dtb
  
  # 存储与文件系统核心包
  DEVICE_PACKAGES := kmod-mmc kmod-sdhci-mtk kmod-fs-f2fs f2fs-tools f2fsck \
	parted lsblk blkid block-mount kmod-zram zram-swap
  
  IMAGES := sysupgrade.bin
  # ✅ 修正：变量引用格式
  IMAGE/sysupgrade.bin := append-kernel | pad-to $(KERNEL_SIZE) | append-rootfs | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
