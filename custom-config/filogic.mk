define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 (eMMC)
  DEVICE_ALT0_VENDOR := SL
  DEVICE_ALT0_MODEL := SL3000
  DEVICE_ALT0_VARIANT := eMMC 1024MB Rootfs
  
  # 物理锁定标识符：必须与原厂导出字符串完全一致
  SUPPORTED_DEVICES := sl,3000-emmc
  # 24.10 刷机校验必需参数
  DEVICE_COMPAT_VERSION := 1.1
  
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  
  # 物理空间定义：128MB Kernel / 1024MB Rootfs
  KERNEL_SIZE := 131072k
  BOARD_ROOTFS_PARTSIZE := 1024
  IMAGE_SIZE := 1152M
  
  KERNEL := kernel-bin | lzma | append-dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | append-dtb
  
  DEVICE_PACKAGES := kmod-mmc kmod-sdhci-mtk kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap
                    
  IMAGES := sysupgrade.bin factory.bin
  # 强制注入元数据并执行边界检查
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | append-metadata | check-size
  IMAGE/factory.bin := append-kernel | append-rootfs
endef
TARGET_DEVICES += 3000-emmc
