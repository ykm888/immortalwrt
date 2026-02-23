#!/bin/bash
# 物理熔断：SL-3000 整合版补丁脚本
# 严禁画蛇添足 | 结构死锁 | 修复工作流路径偏移导致的注入失败
set -eo pipefail

# 1. 物理定位根目录
# 无论脚本在 openwrt 目录内还是外执行，都能准确定位 custom-config
if [ -d "../custom-config" ]; then
    ROOT_DIR=".."
else
    ROOT_DIR="."
fi

# 2. --- 第一阶段：Feeds 注入 ---
# 确保在 openwrt 目录下操作 feeds 文件
if [ -f "feeds.conf.default" ]; then
    if ! grep -q "helloworld" feeds.conf.default; then
        sed -i '/helloworld/d' feeds.conf.default
        printf "src-git helloworld https://github.com/fw876/helloworld\n" >> feeds.conf.default
    fi
fi

# 3. --- 第二阶段：三件套物理注入 ---

# 物理创建 24.10 必需路径
mkdir -p target/linux/mediatek/dts/mediatek
mkdir -p target/linux/mediatek/image/

# 物理注入 DTS (使用 ROOT_DIR 锁定物理路径)
if [ -f "$ROOT_DIR/custom-config/mt7981b-3000-emmc.dts" ]; then
    cp -f $ROOT_DIR/custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mediatek/mt7981b-sl-3000-emmc.dts
    cp -f $ROOT_DIR/custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts
fi

# 物理注入 MK 配置
if [ -f "$ROOT_DIR/custom-config/filogic.mk" ]; then
    cp -f $ROOT_DIR/custom-config/filogic.mk target/linux/mediatek/image/filogic.mk
fi

# 4. --- 物理校准 .config ---
if [ -f ".config" ]; then
    # 锁定内核 6.6
    sed -i 's/CONFIG_LINUX_5_4=y/# CONFIG_LINUX_5_4 is not set/g' .config
    grep -q "CONFIG_LINUX_6_6=y" .config || printf "CONFIG_LINUX_6_6=y\n" >> .config
    # 强制开启 U-Boot 编译开关，确保生成 fip.bin
    printf "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y\n" >> .config
fi
