#!/bin/bash

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}"

cd "${WORKDIR}"

# 1. Feeds 修改 (回退源头封锁，恢复默认 helloworld)
sed -i '/helloworld/d' feeds.conf.default 2>/dev/null
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# 2. [物理源码补齐]
mkdir -p dl
[ ! -f "dl/u-boot-2024.10.tar.bz2" ] && wget -t 3 -T 30 -O dl/u-boot-2024.10.tar.bz2 https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2

# 3. 硬件补丁注入
if [ -f "${SRC_DIR}/custom-config/mt7981b-3000-emmc.dts" ]; then
    cp -f "${SRC_DIR}/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/ 2>/dev/null
    mkdir -p target/linux/mediatek/dts/mediatek/
    cp -f "${SRC_DIR}/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/mediatek/
fi
if [ -f "${SRC_DIR}/custom-config/filogic.mk" ]; then
    cp -f "${SRC_DIR}/custom-config/filogic.mk" target/linux/mediatek/image/filogic.mk
fi

# 4. U-Boot 构建锁定
[ -f .config ] && sed -i 's/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-.*=n/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-.*=y/g' .config
[ -f .config ] && sed -i 's/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=n/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y/g' .config

# 5. 依赖修复
if [ -f package/kernel/mt76/Makefile ]; then
    sed -i 's/PKG_BUILD_DEPENDS:=/PKG_BUILD_DEPENDS:=mac80211 /g' package/kernel/mt76/Makefile
fi

# 6. IP 修改
[ -f package/base-files/files/bin/config_generate ] && \
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate
