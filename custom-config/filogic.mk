define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 (eMMC)
  # 物理锁定标识符
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_COMPAT_VERSION := 1.1
  
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  
  # 物理分区锁定
  KERNEL_SIZE := 131072k
  BOARD_ROOTFS_PARTSIZE := 1024
  IMAGE_SIZE := 1152M
  
  KERNEL := kernel-bin | lzma | append-dtb
  IMAGES := sysupgrade.bin factory.bin
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | append-metadata | check-size
endef
TARGET_DEVICES += 3000-emmc
