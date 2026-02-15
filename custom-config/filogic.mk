define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_ALT0_VENDOR := SL
  DEVICE_ALT0_MODEL := SL3000
  SUPPORTED_DEVICES := sl,3000-emmc 3000-emmc sl3000-emmc mediatek,mt7981
  DEVICE_COMPAT_VERSION := 1.0

  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek

  # 物理偏移锁定：128MB 内核空间
  KERNEL_SIZE := 134217728
  # 固件总上限：设置为 512MB（对于 128GB eMMC 来说绰绰有余）
  IMAGE_SIZE := 536870912

  KERNEL := kernel-bin | lzma | append-dtb
  # 针对无 USB 硬件优化：仅保留 eMMC 核心驱动与本地存储管理工具
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap \
                    kmod-gpt kmod-part-msdos luci-app-diskman

  IMAGES := sysupgrade.bin
  # 物理死锁：强制填充至 128MB，确保与 DTS 分区契合
  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += 3000-emmc
