#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: sl3000-patch.sh
# Description: 整合成功案例原文，物理修复硬件路径与U-Boot锁定
#

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}"

cd "${WORKDIR}"

# --- [原文照抄：成功案例 diy-part1.sh 逻辑] ---
# Add a feed source
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default


# --- [原文照抄：成功案例 diy-part2.sh 逻辑] ---
# Modify default IP (物理修复为用户要求的 192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate


# --- [物理修复：注入仓库三件套硬件补丁] ---
if [ -f "${SRC_DIR}/custom-config/mt7981b-3000-emmc.dts" ]; then
    cp -f "${SRC_DIR}/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/ 2>/dev/null
    mkdir -p target/linux/mediatek/dts/mediatek/
    cp -f "${SRC_DIR}/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/mediatek/
fi

if [ -f "${SRC_DIR}/custom-config/filogic.mk" ]; then
    cp -f "${SRC_DIR}/custom-config/filogic.mk" target/linux/mediatek/image/filogic.mk
fi

# 物理源码补齐 (针对 U-Boot 编译环境)
mkdir -p dl
[ ! -f "dl/u-boot-2024.10.tar.bz2" ] && wget -t 3 -T 30 -O dl/u-boot-2024.10.tar.bz2 https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2


# --- [物理修复：U-Boot 构建锁定] ---
[ -f .config ] && sed -i 's/.*CONFIG_PACKAGE_mt7981-atf-mtk-uboot-.*=n/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y/g' .config
[ -f .config ] && sed -i 's/.*CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc.*/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y/g' .config
