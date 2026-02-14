define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_ALT0_VENDOR := SL
  DEVICE_ALT0_MODEL := SL3000
  # 1. 物理身份对齐：首位必须匹配 GPT 旧系统中的识别码 sl,3000-emmc
  SUPPORTED_DEVICES := sl,3000-emmc 3000-emmc sl3000-emmc mediatek,mt7981
  
  # 2. 逻辑兼容修复：强制版本降为 1.0，防止 23.05 拦截“未来版本”
  DEVICE_COMPAT_VERSION := 1.0

  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek

  # 3. 物理布局对齐：锁定 128MB 内核偏移，确保数据精准压入 GPT 原有的空隙
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 1207959552

  KERNEL := kernel-bin | append-dtb | lzma
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap

  IMAGES := sysupgrade.bin
  # 4. 封装顺序对齐：确保 Metadata 签名在物理文件最末尾，保证校验通过
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += 3000-emmc
