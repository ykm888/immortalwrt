define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 (eMMC)
  DEVICE_ALT0_VENDOR := SL
  DEVICE_ALT0_MODEL := SL3000
  DEVICE_ALT0_VARIANT := eMMC 1024MB Rootfs
  # 物理锁定：必须与 DTS 文件名 mt7981b-3000-emmc.dts 对应
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  # 物理对齐：包含原厂 23.05 导出指纹，彻底解决 Invalid image type 报错
  SUPPORTED_DEVICES := sl,3000-emmc mediatek,mt7981
  KERNEL_SIZE := 131072k
  BOARD_ROOTFS_PARTSIZE := 1024
  KERNEL := kernel-bin | lzma | append-dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | append-dtb
  DEVICE_PACKAGES := kmod-mmc kmod-sdhci-mtk kmod-fs-f2fs f2fs-tools f2fsck parted lsblk blkid block-mount kmod-zram zram-swap
  IMAGES := sysupgrade.bin factory.bin
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | append-metadata
  IMAGE/factory.bin := append-kernel | append-rootfs
endef
TARGET_DEVICES += 3000-emmc
