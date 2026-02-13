define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_ALT0_VENDOR := SL
  DEVICE_ALT0_MODEL := SL3000
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek

  # 物理修正：使用十六进制规避 Shell 报错，对齐 DTS 128MB 分区长度
  KERNEL_SIZE := 0x8000000
  IMAGE_SIZE := 1152M

  # 物理修正：移除二次 lzma，确保 U-Boot 能正确引导
  KERNEL := kernel-bin | append-dtb | lzma

  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap

  IMAGES := sysupgrade.bin
  # 物理修正：pad-to 使用变量引用，确保二进制填充绝对对齐 0x8000000
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | append-metadata | check-size
endef
TARGET_DEVICES += 3000-emmc
