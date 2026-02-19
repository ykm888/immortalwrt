define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  
  KERNEL_SIZE := 131072k
  IMAGE_SIZE := 524288k

  KERNEL := kernel-bin | lzma | append-dtb
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap \
                    luci-app-diskman uboot-envtools

  # 🔥 物理物理新增：定义产物收割逻辑
  ARTIFACTS := fip.bin
  ARTIFACT/fip.bin := mt7981-bl31-atf-install | mt7981-u-boot-install sl3000-emmc

  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := append-kernel | pad-to 128m | append-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
