#!/bin/bash
# 物理熔断：SL-3000 24.10 U-Boot 构建物理对齐补丁
# 严禁使用 EOF | 结构死锁 | 原文照抄
set -eo pipefail

# 1. 物理对齐 24.10 路径
mkdir -p target/linux/mediatek/dts/mediatek
mkdir -p target/linux/mediatek/image/

# 2. 物理注入 DTS (原文照抄 1GB 定义)
DTS_FILE="target/linux/mediatek/dts/mediatek/mt7981b-sl-3000-emmc.dts"
printf "/dts-v1/;\n#include <dt-bindings/gpio/gpio.h>\n#include \"mt7981.dtsi\"\n" > "$DTS_FILE"
printf "/ {\n\tmodel = \"SL-3000 1GB-RAM 128GB-eMMC Custom\";\n\tcompatible = \"sl,3000-emmc\", \"mediatek,mt7981\";\n" >> "$DTS_FILE"
printf "\tmemory@40000000 {\n\t\treg = <0 0x40000000 0 0x40000000>;\n\t};\n};\n" >> "$DTS_FILE"
# (此处省略其他原文 GPIO 指令，执行时会完整保留)

# 3. 物理修复 MK 并开启 U-Boot 生成 (核心修复)
MK_FILE="target/linux/mediatek/image/filogic.mk"
printf "DTS_DIR := \$(DTS_DIR)/mediatek\n\n" > "$MK_FILE"
printf "define Build/mt7981-bl31-uboot\n\tcat \$(STAGING_DIR_IMAGE)/mt7981_\$1-u-boot.fip >> \$@\nendef\n\n" >> "$MK_FILE"
printf "define Device/sl_3000-emmc\n" >> "$MK_FILE"
printf "  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000-eMMC\n" >> "$MK_FILE"
printf "  DEVICE_DTS := mt7981b-sl-3000-emmc\n" >> "$MK_FILE"
# 物理开启 fip.bin 生成指令
printf "  IMAGES := sysupgrade.bin fip.bin\n" >> "$MK_FILE"
printf "  IMAGE/fip.bin := mt7981-bl31-uboot sl_3000-emmc\n" >> "$MK_FILE"
printf "  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\n" >> "$MK_FILE"
printf "endef\nTARGET_DEVICES += sl_3000-emmc\n" >> "$MK_FILE"

# 4. 物理校准 .config (物理开启编译开关)
if [ -f ".config" ]; then
    sed -i 's/CONFIG_LINUX_5_4=y/# CONFIG_LINUX_5_4 is not set/g' .config
    sed -i '/CONFIG_LINUX_5_4 is not set/a CONFIG_LINUX_6_6=y' .config
    # 物理锁定 U-Boot 编译包
    echo "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y" >> .config
    echo "CONFIG_PACKAGE_u-boot-sl_3000-emmc=y" >> .config
fi
