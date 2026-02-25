#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# --- [原文照抄：成功案例逻辑] ---
# Modify default IP (192.168.1.1 -> 192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# --- [物理修复：验证通过的 ebtables 源码补齐] ---
mkdir -p dl
EBT_FILE="ebtables-2018.06.27~48cff25d.tar.zst"
if [ ! -f "dl/$EBT_FILE" ]; then
    wget -t 3 -T 30 -O "dl/$EBT_FILE" "https://sources.openwrt.org/$EBT_FILE"
fi

# --- [物理对位：三件套硬件补丁注入] ---
# 此时处于 openwrt 目录下，使用 ../ 访问仓库根目录的自定义配置
cp -f ../custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mediatek/ 2>/dev/null
cp -f ../custom-config/filogic.mk target/linux/mediatek/image/filogic.mk 2>/dev/null

# --- [物理手术：解决 OpenSSL 冲突与 1GB 内存锁定] ---
if [ -f .config ]; then
    # 1. 修复报错：物理切断 libopenssl-afalg_sync 冲突项
    sed -i 's/CONFIG_PACKAGE_libopenssl-afalg_sync=y/# CONFIG_PACKAGE_libopenssl-afalg_sync is not set/g' .config
    
    # 2. 物理锁定：开启 1GB 内存支持 (HIGHMEM)
    sed -i 's/CONFIG_LOW_MEM_256M=y/# CONFIG_LOW_MEM_256M is not set/g' .config
    echo "CONFIG_HIGHMEM=y" >> .config
    echo "CONFIG_TARGET_OPTIONS=y" >> .config
    echo "CONFIG_TARGET_RAM_OPTIMIZE=y" >> .config

    # 3. 物理锁定：U-Boot 构建目标
    sed -i 's/.*CONFIG_PACKAGE_mt7981-atf-mtk-uboot-.*=n/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y/g' .config
    sed -i 's/.*CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc.*/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y/g' .config
fi

# 物理源码补齐 (U-Boot)
[ ! -f "dl/u-boot-2024.10.tar.bz2" ] && wget -t 3 -T 30 -O dl/u-boot-2024.10.tar.bz2 https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2
