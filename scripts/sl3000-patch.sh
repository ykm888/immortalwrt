#!/bin/bash
# 物理熔断：SL-3000 路径与产物物理对齐脚本
# 严禁画蛇添足 | 结构死锁 | 物理修复 Error 1 & No such file
set -eo pipefail

# 1. 物理注入 Feeds
sed -i '/helloworld/d' feeds.conf.default
printf "src-git helloworld https://github.com/fw876/helloworld\n" >> feeds.conf.default

# 2. 物理创建 24.10 必需路径
mkdir -p target/linux/mediatek/dts/mediatek
mkdir -p target/linux/mediatek/image/

# 3. 物理注入 DTS 原文 (基于 custom-config/mt7981b-3000-emmc.dts)
# 审计：确保双层路径均有文件，防止编译器查找失败
if [ -f "custom-config/mt7981b-3000-emmc.dts" ]; then
    cp custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mediatek/mt7981b-sl-3000-emmc.dts
    cp custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts
fi

# 4. 物理注入 MK 配置 (基于 custom-config/filogic.mk)
if [ -f "custom-config/filogic.mk" ]; then
    cp custom-config/filogic.mk target/linux/mediatek/image/filogic.mk
fi

# 5. 物理校准 .config 内核与 U-Boot 包开关
if [ -f ".config" ]; then
    sed -i 's/CONFIG_LINUX_5_4=y/# CONFIG_LINUX_5_4 is not set/g' .config
    grep -q "CONFIG_LINUX_6_6=y" .config || printf "CONFIG_LINUX_6_6=y\n" >> .config
    printf "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y\n" >> .config
fi
