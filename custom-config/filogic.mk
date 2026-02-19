define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  
  # 物理死锁：直接使用字节数值，严禁使用 k/m 缩写
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 536870912

  KERNEL := kernel-bin | lzma | append-dtb
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap \
                    luci-app-diskman uboot-envtools

  ARTIFACTS := fip.bin
  ARTIFACT/fip.bin := mt7981-bl31-atf-install | mt7981-u-boot-install sl3000-emmc

  IMAGES := sysupgrade.bin
  # 🔥 彻底解决：pad-to 后面必须使用纯数字，防止 dd 命令报错
  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
