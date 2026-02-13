define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_ALT0_VENDOR := SL
  DEVICE_ALT0_MODEL := SL3000
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek

  # 物理修正：使用纯十进制字节 (128*1024*1024) 规避 dd 报错
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 1152M

  KERNEL := kernel-bin | append-dtb | lzma

  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap

  IMAGES := sysupgrade.bin
  # 物理对齐：使用十进制变量进行填充
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | append-metadata | check-size
endef
TARGET_DEVICES += 3000-emmc
