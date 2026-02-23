#!/bin/bash
# 物理熔断：修复 DTS 查找路径死锁 Error 1
# 严禁使用 EOF | 结构死锁 | 原文照抄
set -eo pipefail

# 1. 物理清理 & 注入 Feeds
sed -i '/helloworld/d' feeds.conf.default
printf "src-git helloworld https://github.com/fw876/helloworld\n" >> feeds.conf.default

# 2. 物理创建 24.10 必需路径
mkdir -p target/linux/mediatek/dts/mediatek
mkdir -p target/linux/mediatek/image/

# 3. 物理注入 DTS 原文 (printf 锁定路径)
DTS_FILE="target/linux/mediatek/dts/mediatek/mt7981b-sl-3000-emmc.dts"
printf "/dts-v1/;\n#include <dt-bindings/gpio/gpio.h>\n#include <dt-bindings/input/input.h>\n#include <dt-bindings/leds/common.h>\n#include \"mt7981.dtsi\"\n\n" > "$DTS_FILE"
printf "/ {\n\tmodel = \"SL-3000 1GB-RAM 128GB-eMMC Custom\";\n\tcompatible = \"sl,3000-emmc\", \"mediatek,mt7981\";\n" >> "$DTS_FILE"
printf "\tmemory@40000000 {\n\t\treg = <0 0x40000000 0 0x40000000>;\n\t};\n};\n" >> "$DTS_FILE"

# [物理修复点] 24.10 编译器默认看 ../dts/，我们需要建立物理链接或修正 MK
# 这里选择在上一级也放一个，确保编译器必中
cp "$DTS_FILE" target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts

# 4. 物理重写 filogic.mk (物理锁定路径指向)
MK_FILE="target/linux/mediatek/image/filogic.mk"
printf "DTS_DIR := \$(DTS_DIR)/mediatek\n\n" > "$MK_FILE"
printf "define Build/mt7981-bl31-uboot\n\tcat \$(STAGING_DIR_IMAGE)/mt7981_\$1-u-boot.fip >> \$@\nendef\n\n" >> "$MK_FILE"
printf "define Build/mt798x-gpt\n\tcp \$@ \$@.tmp 2>/dev/null || true\n\tptgen -g -o \$@.tmp -a 1 -l 1024 \\\\\n\t\t\t-t 0x83 -N ubootenv -r -p 512k@4M \\\\\n\t\t\t-t 0x83 -N factory -r -p 2M@4608k \\\\\n\t\t\t-t 0xef -N fip -r -p 4M@6656k \\\\\n\t\t\t\t-N recovery -r -p 32M@12M \\\\\n\t\t\$(if \$(findstring emmc,\$1), -t 0x2e -N production -p \$(CONFIG_TARGET_ROOTFS_PARTSIZE)M@64M)\n\tcat \$@.tmp >> \$@\n\trm \$@.tmp\nendef\n\n" >> "$MK_FILE"

printf "define Device/sl_3000-emmc\n" >> "$MK_FILE"
printf "  DEVICE_VENDOR := SL\n" >> "$MK_FILE"
printf "  DEVICE_MODEL := 3000-eMMC\n" >> "$MK_FILE"
printf "  DEVICE_DTS := mt7981b-sl-3000-emmc\n" >> "$MK_FILE"
# [物理对齐] 明确指定 DTS 目录为相对 image 目录的上一级 dts
printf "  DEVICE_DTS_DIR := ../dts\n" >> "$MK_FILE"
printf "  SUPPORTED_DEVICES := sl,3000-emmc\n" >> "$MK_FILE"
printf "  IMAGES := sysupgrade.bin fip.bin\n" >> "$MK_FILE"
printf "  IMAGE/fip.bin := mt7981-bl31-uboot sl_3000-emmc\n" >> "$MK_FILE"
printf "  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\n" >> "$MK_FILE"
printf "  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools e2fsprogs f2fsck mkf2fs kmod-zram zram-swap\n" >> "$MK_FILE"
printf "endef\nTARGET_DEVICES += sl_3000-emmc\n" >> "$MK_FILE"

# 5. 物理校准 .config (物理强制开启 6.6 内核)
if [ -f ".config" ]; then
    sed -i 's/CONFIG_LINUX_5_4=y/# CONFIG_LINUX_5_4 is not set/g' .config
    # 物理覆盖内核配置，确保 aarch64_cortex-a53 架构正确
    if ! grep -q "CONFIG_LINUX_6_6=y" .config; then
        printf "CONFIG_LINUX_6_6=y\n" >> .config
    fi
    printf "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y\n" >> .config
fi
