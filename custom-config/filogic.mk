define Device/3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_ALT0_VENDOR := SL
  DEVICE_ALT0_MODEL := SL3000
  # 1. 物理身份对齐：首位必须匹配 23.05 系统识别码 sl,3000-emmc
  SUPPORTED_DEVICES := sl,3000-emmc 3000-emmc sl3000-emmc mediatek,mt7981
  
  # 2. 逻辑兼容修复：强制版本降为 1.0，绕过旧系统对 1.1 的升级拦截
  DEVICE_COMPAT_VERSION := 1.0

  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek

  # 3. 物理锁定：内核偏移 128MB (134217728 bytes)，这是防止红灯的核心
  KERNEL_SIZE := 134217728
  # 4. 物理扩容：总大小 256MB (268435456 bytes)，给系统留出 128MB 呼吸空间
  # 这个尺寸 U-Boot 绝对能刷进去，且能覆盖旧 GPT 头
  IMAGE_SIZE := 268435456

  KERNEL := kernel-bin | append-dtb | lzma
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap

  IMAGES := sysupgrade.bin
  # 5. 封装逻辑对齐：确保 128MB 物理填充后紧跟 Rootfs，metadata 在文件末尾
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += 3000-emmc
