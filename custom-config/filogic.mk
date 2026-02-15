define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_ALT0_VENDOR := SL
  DEVICE_ALT0_MODEL := SL3000
  SUPPORTED_DEVICES := sl,3000-emmc 3000-emmc sl3000-emmc mediatek,mt7981
  DEVICE_COMPAT_VERSION := 1.0
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek

  # 物理偏移硬锁定：128MB = 134217728 Bytes
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 268435456

  KERNEL := kernel-bin | lzma | append-dtb
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap \
                    kmod-gpt kmod-part-msdos

  IMAGES := sysupgrade.bin
  # 物理死锁：强制填充 134217728 字节，确保 Rootfs 物理起始点在 128MB 处
  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += 3000-emmc
