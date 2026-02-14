define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_ALT0_VENDOR := SL
  DEVICE_ALT0_MODEL := SL3000
  # 物理身份对齐：首位必须匹配你 cat /tmp/sysinfo/board_name 的结果
  SUPPORTED_DEVICES := sl,3000-emmc 3000-emmc sl3000-emmc mediatek,mt7981
  
  # 逻辑修复：强制设为 1.0，彻底解决 23.05 拦截 1.1 版本的逻辑死结
  DEVICE_COMPAT_VERSION := 1.0

  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek

  # 物理偏移锁定：128MB (134217728 bytes)，确保内核与 DTS 分区表严丝合缝
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 1207959552

  KERNEL := kernel-bin | append-dtb | lzma
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap

  IMAGES := sysupgrade.bin
  # 物理打包顺序对齐：确保 Metadata（JSON 签名）处于文件绝对末尾，且通过 check-size 校验
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += 3000-emmc
