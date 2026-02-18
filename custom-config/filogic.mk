define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc mediatek,mt7981
  
  # 物理偏移锁定
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 536870912

  KERNEL := kernel-bin | lzma | append-dtb
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap \
                    luci-app-diskman uboot-envtools

  IMAGES := sysupgrade.bin
  # 物理死锁：强制填充 128MB 对齐 DTS 分区表
  IMAGE/sysupgrade.bin := append-kernel | pad-to 128m | append-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
