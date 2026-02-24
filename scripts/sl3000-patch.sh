#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: sl3000-patch.sh
# 整合成功案例原文，物理修复 ebtables 404 错误、硬件路径与 U-Boot 锁定
#

# 物理路径定位
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "${REPO_ROOT}/openwrt" || exit 1

# --- [原文照抄：成功案例 diy-part1.sh 逻辑] ---
# Add a feed source
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default


# --- [物理修复：验证通过的 ebtables 源码补齐] ---
# 编译器 Makefile 中的 Git 链接已失效，直接物理补齐 dl 包绕过 404
mkdir -p dl
EBT_FILE="ebtables-2018.06.27~48cff25d.tar.zst"
if [ ! -f "dl/$EBT_FILE" ]; then
    wget -t 3 -T 30 -O "dl/$EBT_FILE" "https://sources.openwrt.org/$EBT_FILE"
fi


# --- [原文照抄：成功案例 diy-part2.sh 逻辑] ---
# Modify default IP (192.168.6.1)
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

# 物理源码补齐 (U-Boot)
[ ! -f "dl/u-boot-2024.10.tar.bz2" ] && wget -t 3 -T 30 -O dl/u-boot-2024.10.tar.bz2 https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2


# --- [物理修复：U-Boot 构建锁定] ---
[ -f .config ] && sed -i 's/.*CONFIG_PACKAGE_mt7981-atf-mtk-uboot-.*=n/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y/g' .config
[ -f .config ] && sed -i 's/.*CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc.*/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y/g' .config
