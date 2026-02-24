#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: sl3000-patch.sh
# 整合成功案例原文，物理修复硬件路径与U-Boot锁定
#

# 物理路径定位（放宽格式：动态获取根目录，确保物理执行无误）
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "${REPO_ROOT}/openwrt" || exit 1

# --- [原文照抄：成功案例 diy-part1.sh 逻辑] ---
# Add a feed source
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default


# --- [原文照抄：成功案例 diy-part2.sh 逻辑] ---
# Modify default IP (物理修复为 192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate


# --- [物理修复：注入三件套硬件补丁] ---
# 1. 注入 DTS 文件
DTS_SRC="${REPO_ROOT}/custom-config/mt7981b-3000-emmc.dts"
if [ -f "$DTS_SRC" ]; then
    cp -f "$DTS_SRC" target/linux/mediatek/dts/ 2>/dev/null
    mkdir -p target/linux/mediatek/dts/mediatek/
    cp -f "$DTS_SRC" target/linux/mediatek/dts/mediatek/
fi

# 2. 注入 MK 文件
MK_SRC="${REPO_ROOT}/custom-config/filogic.mk"
if [ -f "$MK_SRC" ]; then
    cp -f "$MK_SRC" target/linux/mediatek/image/filogic.mk
fi

# 3. 物理源码补齐 (U-Boot 源码包)
mkdir -p dl
[ ! -f "dl/u-boot-2024.10.tar.bz2" ] && wget -t 3 -T 30 -O dl/u-boot-2024.10.tar.bz2 https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2


# --- [物理修复：U-Boot 构建锁定要求] ---
# 4. U-Boot 构建锁定
[ -f .config ] && sed -i 's/.*CONFIG_PACKAGE_mt7981-atf-mtk-uboot-.*=n/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y/g' .config
[ -f .config ] && sed -i 's/.*CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc.*/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y/g' .config
