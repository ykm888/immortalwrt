define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000-eMMC
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  
  # 物理死锁：字节纯数字，防止 dd 报错
  KERNEL_SIZE := 134217728
  IMAGE_SIZE := 536870912

  KERNEL := kernel-bin | lzma | append-dtb
  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \
                    parted lsblk blkid block-mount kmod-zram zram-swap \
                    luci-app-diskman uboot-envtools

  # 物理修复：移除导致 Missing Build 报错的 ARTIFACTS 段落
  # 镜像生成逻辑
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | check-size | append-metadata
endef
TARGET_DEVICES += sl3000-emmc

# 物理修复：针对 uboot-mediatek 报错点的 sed 修复指令
# 注意：以下内容通常应在 package/boot/uboot-mediatek/Makefile 中执行
# 修复了原先缺失的闭合斜杠 / 并在行尾插入
# sed -i '/dtb- +=/ s/$$/ mt7981-sl3000-emmc.dtb/' $(PKG_BUILD_DIR)/arch/arm/dts/Makefile
