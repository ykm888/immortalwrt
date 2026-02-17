define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_ALT0_VENDOR := SL
  DEVICE_ALT0_MODEL := SL3000
  # 物理对齐：首位必须是 23.05 的 Compatible 身份
  SUPPORTED_DEVICES := sl,3000-emmc 3000-emmc sl3000-emmc mediatek,mt7981
  DEVICE_COMPAT_VERSION := 1.0

  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek

  # 物理偏移锁定：128MB 内核空间 (128 * 1024 * 1024)
  KERNEL_SIZE := 134217728
  # 固件总上限 (512MB)
  IMAGE_SIZE := 536870912

  KERNEL := kernel-bin | lzma | append-dtb
  # 物理加固：增加 eMMC 稳定性驱动与环境变量工具
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap \
                    kmod-gpt kmod-part-msdos luci-app-diskman uboot-envtools

  IMAGES := sysupgrade.bin
  # 物理死锁逻辑：
  # 1. 拼接内核 -> 2. 物理填充至 128MB (确保 rootfs 从 0x8380000 开始) -> 3. 拼接 rootfs
  IMAGE/sysupgrade.bin := append-kernel | pad-to 128m | append-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += 3000-emmc
