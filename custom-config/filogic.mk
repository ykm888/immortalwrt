define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_ALT0_VENDOR := SL
  DEVICE_ALT0_MODEL := SL3000
  # 物理身份最终对齐：
  # 1. 3000-emmc (对应你 23.05 的 board_name)
  # 2. sl,3000-emmc (对应 24.10 DTS 标准 ID)
  # 3. mediatek,mt7981 (通用硬件 ID)
  SUPPORTED_DEVICES := 3000-emmc sl,3000-emmc sl3000-emmc mediatek,mt7981
  DEVICE_COMPAT_VERSION := 1.1

  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek

  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 1207959552

  KERNEL := kernel-bin | append-dtb | lzma
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap

  IMAGES := sysupgrade.bin
  # 物理打包顺序修复：确保 Metadata 处于文件绝对末尾
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += 3000-emmc
