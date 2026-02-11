# 司络 SL3000 (eMMC) 设备配置 - 与 .config/DTS 严格对齐
define Device/sl3000-emmc
  # 设备基础信息（符合 ImmortalWrt 命名规范）
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 (eMMC)
  DEVICE_ALT0_VENDOR := 司络
  DEVICE_ALT0_MODEL := SL3000
  DEVICE_ALT0_VARIANT := eMMC 512MB Rootfs
  
  # 设备树配置（与 DTS 文件名完全对齐）
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc mediatek,mt7981
  
  # 分区大小（与 .config 100% 同步）
  KERNEL_SIZE := 131072k  # 对应 CONFIG_TARGET_KERNEL_PARTSIZE=128
  BOARD_ROOTFS_PARTSIZE := 512  # 对应 CONFIG_TARGET_ROOTFS_PARTSIZE=512
  
  # 内核编译逻辑（ImmortalWrt 24.10 标准流程，合并 DTB）
  KERNEL := kernel-bin | lzma | append-dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | append-dtb
  
  # 核心驱动与工具包（与 .config 启用项完全一致）
  DEVICE_PACKAGES := \
    kmod-mmc \
    kmod-sdhci-mtk \
    kmod-fs-f2fs \
    f2fs-tools \
    f2fsck \
    parted \
    lsblk \
    blkid \
    block-mount \
    kmod-zram \
    zram-swap
  
  # 固件镜像配置（squashfs 格式，与 .config 文件系统对齐）
  IMAGES := sysupgrade.bin factory.bin
  # sysupgrade 镜像（刷机升级用，符合官方打包标准）
  IMAGE/sysupgrade.bin := \
    append-kernel | \
    pad-to $(KERNEL_SIZE) | \
    append-rootfs | \
    append-metadata | \
    check-size $(shell echo $$((128 + 512)))*1024k  # 内核+根分区总大小校验
  # factory 镜像（初始刷机用，保留官方格式）
  IMAGE/factory.bin := \
    append-kernel | \
    pad-to $(KERNEL_SIZE) | \
    append-rootfs | \
    check-size $(shell echo $$((128 + 512)))*1024k
endef
# 注册设备（编译系统必须识别的关键配置）
TARGET_DEVICES += sl3000-emmc
