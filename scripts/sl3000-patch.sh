#!/bin/bash
# 物理熔断：SL-3000 24.10 核心物理对齐补丁（含 U-boot 生成）
set -eo pipefail

# 1. 注入源 (原文照抄)
echo 'src-git helloworld https://github.com/fw876/helloworld' >> feeds.conf.default

# 2. 物理创建 24.10 DTS 路径
mkdir -p target/linux/mediatek/dts/mediatek

# 3. 物理同步配置文件 (结果导向)
[ -f "custom-config/mt7981b-3000-emmc.dts" ] && cp -f custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mediatek/mt7981b-sl-3000-emmc.dts

# 4. 物理重写 filogic.mk (加入 U-boot 构建逻辑)
TARGET_MK="target/linux/mediatek/image/filogic.mk"
printf "DTS_DIR := \$(DTS_DIR)/mediatek\n\ndefine Image/Prepare\n\trm -f \$(KDIR)/ubi_mark\n\techo -ne '\\\\xde\\\\xad\\\\xc0\\\\xde' > \$(KDIR)/ubi_mark\nendef\n\n" > $TARGET_MK
printf "define Build/mt7981-bl2\n\tcat \$(STAGING_DIR_IMAGE)/mt7981-\$1-bl2.img >> \$@\nendef\n\n" >> $TARGET_MK
printf "define Build/mt7981-bl31-uboot\n\tcat \$(STAGING_DIR_IMAGE)/mt7981_\$1-u-boot.fip >> \$@\nendef\n\n" >> $TARGET_MK
printf "define Build/mt798x-gpt\n\tcp \$@ \$@.tmp 2>/dev/null || true\n\tptgen -g -o \$@.tmp -a 1 -l 1024 \\\\\n\t\t\$(if \$(findstring sdmmc,\$1), -H -t 0x83 -N bl2 -r -p 4079k@17k) \\\\\n\t\t\t-t 0x83 -N ubootenv -r -p 512k@4M \\\\\n\t\t\t-t 0x83 -N factory -r -p 2M@4608k \\\\\n\t\t\t-t 0xef -N fip -r -p 4M@6656k \\\\\n\t\t\t\t-N recovery -r -p 32M@12M \\\\\n\t\t\$(if \$(findstring emmc,\$1), -t 0x2e -N production -p \$(CONFIG_TARGET_ROOTFS_PARTSIZE)M@64M)\n\tcat \$@.tmp >> \$@\n\trm \$@.tmp\nendef\n\n" >> $TARGET_MK
printf "define Device/sl_3000-emmc\n  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000-eMMC\n  DEVICE_DTS := mt7981b-sl-3000-emmc\n  DEVICE_DTS_DIR := ../dts\n  SUPPORTED_DEVICES := sl,3000-emmc\n  IMAGES := sysupgrade.bin factory.bin fip.bin\n  IMAGE/factory.bin := append-kernel | pad-to 128k | append-rootfs | mt798x-gpt emmc\n  IMAGE/fip.bin := mt7981-bl31-uboot sl_3000-emmc\n  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools e2fsprogs f2fsck mkf2fs kmod-zram zram-swap\n  IMAGE_SIZE := 512M\n  KERNEL := kernel-bin | lzma | fit lzma \$\$(KDIR)/image-\$\$(firstword \$\$(DEVICE_DTS)).dtb\n  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\nendef\nTARGET_DEVICES += sl_3000-emmc\n" >> $TARGET_MK

# 5. 物理校准 8000 行 .config (熔断旧内核，锁定 U-boot 编译项)
if [ -f ".config" ]; then
    sed -i 's/CONFIG_LINUX_5_4=y/# CONFIG_LINUX_5_4 is not set/g' .config
    echo "CONFIG_LINUX_6_6=y" >> .config
    sed -i 's/sl_3000-emmc/sl_3000-emmc/g' .config # 保持 Device 名称一致
    # 强制开启 U-boot 编译包
    echo "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y" >> .config
    echo "CONFIG_PACKAGE_mtk-bmtedit=y" >> .config
    # 物理补全分区工具
    echo "CONFIG_PACKAGE_fdisk=y" >> .config
    echo "CONFIG_PACKAGE_resize2fs=y" >> .config
fi
