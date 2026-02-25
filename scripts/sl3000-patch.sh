#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: sl3000-patch.sh
# 物理修复：在母本 config 缺失的情况下，强制注入 1GB 内存锁定与 ebtables 补丁
#

# 物理路径定位
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "${REPO_ROOT}/openwrt" || exit 1

# --- [原文照抄：成功案例 diy-part1.sh 逻辑] ---
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# --- [物理修复：验证通过的 ebtables 源码补全] ---
mkdir -p dl
EBT_FILE="ebtables-2018.06.27~48cff25d.tar.zst"
if [ ! -f "dl/$EBT_FILE" ]; then
    wget -t 3 -T 30 -O "dl/$EBT_FILE" "https://sources.openwrt.org/$EBT_FILE"
fi

# --- [原文照抄：成功案例 diy-part2.sh 逻辑] ---
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# --- [物理修复：注入三件套硬件补丁] ---
DTS_SRC="${REPO_ROOT}/custom-config/mt7981b-3000-emmc.dts"
if [ -f "$DTS_SRC" ]; then
    cp -f "$DTS_SRC" target/linux/mediatek/dts/ 2>/dev/null
    mkdir -p target/linux/mediatek/dts/mediatek/
    cp -f "$DTS_SRC" target/linux/mediatek/dts/mediatek/
fi

MK_SRC="${REPO_ROOT}/custom-config/filogic.mk"
if [ -f "$MK_SRC" ]; then
    cp -f "$MK_SRC" target/linux/mediatek/image/filogic.mk
fi

# --- [物理强制：注入 1GB 内存锁定（修复 Config 缺失问题）] ---
if [ -f .config ]; then
    # 1. 物理切断低内存限制（防止默认值干扰）
    sed -i 's/CONFIG_LOW_MEM_256M=y/# CONFIG_LOW_MEM_256M is not set/g' .config
    # 2. 物理追加高内存管理指令
    echo "CONFIG_HIGHMEM=y" >> .config
    # 3. 物理锁定 1GB DDR 布局（确保内核满血）
    echo "CONFIG_TARGET_OPTIONS=y" >> .config
    echo "CONFIG_TARGET_RAM_OPTIMIZE=y" >> .config
    
    # --- [物理修复：U-Boot 构建锁定] ---
    sed -i 's/.*CONFIG_PACKAGE_mt7981-atf-mtk-uboot-.*=n/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y/g' .config
    sed -i 's/.*CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc.*/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y/g' .config
fi

# 物理源码补齐 (U-Boot)
[ ! -f "dl/u-boot-2024.10.tar.bz2" ] && wget -t 3 -T 30 -O dl/u-boot-2024.10.tar.bz2 https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2

exit 0
