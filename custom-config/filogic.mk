define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_ALT0_VENDOR := SL
  DEVICE_ALT0_MODEL := SL3000
  # 物理身份对齐：包含 23.05 识别的所有潜在 ID
  SUPPORTED_DEVICES := 3000-emmc sl,3000-emmc sl3000-emmc mediatek,mt7981
  
  # 【核心修复】：将版本降级为 1.0
  # 彻底解决 (1.0->1.1) 冲突，让旧系统 sysupgrade 脚本物理放行
  DEVICE_COMPAT_VERSION := 1.0

  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek

  # 物理容量锁定：128MB 内核，与 DTS 绝对对齐
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 1207959552

  KERNEL := kernel-bin | append-dtb | lzma
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap

  IMAGES := sysupgrade.bin
  # 物理顺序对齐：确保 check-size 在前，append-metadata 在最后，保证元数据 JSON 块完整
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += 3000-emmc
