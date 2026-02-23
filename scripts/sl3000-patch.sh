#!/bin/bash
# 物理熔断：修复 FIP 文件名拼接错误 (No such file or directory)
# 严禁使用 EOF | 结构死锁 | 原文照抄
set -eo pipefail

# 1. 物理清理 & 注入 Feeds
sed -i '/helloworld/d' feeds.conf.default
printf "src-git helloworld https://github.com/fw876/helloworld\n" >> feeds.conf.default

# 2. 物理创建 & 冗余 DTS 路径 (解决上一轮 Error 1)
mkdir -p target/linux/mediatek/dts/mediatek
DTS_FILE="target/linux/mediatek/dts/mediatek/mt7981b-sl-3000-emmc.dts"
printf "/dts-v1/;\n#include <dt-bindings/gpio/gpio.h>\n#include \"mt7981.dtsi\"\n/ {\n\tmodel = \"SL-3000 1GB-RAM 128GB-eMMC\";\n\tcompatible = \"sl,3000-emmc\", \"mediatek,mt7981\";\n\tmemory@40000000 { reg = <0 0x40000000 0 0x40000000>; };\n};\n" > "$DTS_FILE"
cp "$DTS_FILE" target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts

# 3. 物理重写 filogic.mk (核心修复：校准 FIP 路径拼接)
MK_FILE="target/linux/mediatek/image/filogic.mk"
printf "DTS_DIR := \$(DTS_DIR)/mediatek\n\n" > "$MK_FILE"
# [物理修复点] 修正拼接逻辑，确保能匹配到 staging_dir 里的真实文件名
printf "define Build/mt7981-bl31-uboot\n\tcat \$(STAGING_DIR_IMAGE)/mt7981_\$(1)-u-boot.fip >> \$@\nendef\n\n" >> "$MK_FILE"

printf "define Device/sl_3000-emmc\n" >> "$MK_FILE"
printf "  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000-eMMC\n" >> "$MK_FILE"
printf "  DEVICE_DTS := mt7981b-sl-3000-emmc\n" >> "$MK_FILE"
printf "  DEVICE_DTS_DIR := ../dts\n" >> "$MK_FILE"
printf "  SUPPORTED_DEVICES := sl,3000-emmc\n" >> "$MK_FILE"
printf "  IMAGES := sysupgrade.bin fip.bin\n" >> "$MK_FILE"
# 此处的第二个参数 sl_3000-emmc 会传递给上面的 $(1)
printf "  IMAGE/fip.bin := mt7981-bl31-uboot sl_3000-emmc\n" >> "$MK_FILE"
printf "  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\n" >> "$MK_FILE"
printf "  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools e2fsprogs f2fsck mkf2fs kmod-zram zram-swap\n" >> "$MK_FILE"
printf "endef\nTARGET_DEVICES += sl_3000-emmc\n" >> "$MK_FILE"

# 4. 物理校准 .config (强制锁定编译开关)
if [ -f ".config" ]; then
    sed -i 's/CONFIG_LINUX_5_4=y/# CONFIG_LINUX_5_4 is not set/g' .config
    if ! grep -q "CONFIG_LINUX_6_6=y" .config; then
        printf "CONFIG_LINUX_6_6=y\n" >> .config
    fi
    # 物理开启 U-Boot 包编译，这是产生 .fip 文件的来源
    printf "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y\n" >> .config
fi
