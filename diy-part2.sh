#!/bin/bash
#
# File name: diy-part2.sh
# 物理修复：针对“配置未变但产物偏移”的彻底熔断方案
#

# --- [原文照抄：成功案例逻辑] ---
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# --- [物理修复：ebtables 源码补齐] ---
mkdir -p dl
EBT_FILE="ebtables-2018.06.27~48cff25d.tar.zst"
if [ ! -f "dl/$EBT_FILE" ]; then
    wget -t 3 -T 30 -O "dl/$EBT_FILE" "https://sources.openwrt.org/$EBT_FILE"
fi

# --- [物理对位：三件套硬件补丁注入] ---
cp -f ../custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mediatek/ 2>/dev/null
cp -f ../custom-config/filogic.mk target/linux/mediatek/image/filogic.mk 2>/dev/null

# --- [最高级别物理手术：强制清空干扰 Target] ---
if [ -f .config ]; then
    # 物理彻底删除所有已存在的 Target 相关配置（防止系统默认回滚到 R64）
    sed -i '/CONFIG_TARGET_mediatek/d' .config
    sed -i '/CONFIG_TARGET_BOARD/d' .config
    sed -i '/CONFIG_TARGET_SUBTARGET/d' .config
    sed -i '/CONFIG_TARGET_PROFILE/d' .config
    
    # 物理重新焊死 SL-3000 身份
    echo "CONFIG_TARGET_mediatek=y" >> .config
    echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
    
    # 物理锁定 U-Boot 与 1GB 内存
    echo "CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y" >> .config
    echo "CONFIG_HIGHMEM=y" >> .config

    # 物理修复 OpenSSL 冲突
    sed -i 's/CONFIG_PACKAGE_libopenssl-afalg_sync=y/# CONFIG_PACKAGE_libopenssl-afalg_sync is not set/g' .config
fi

# 物理源码补齐 (U-Boot)
[ ! -f "dl/u-boot-2024.10.tar.bz2" ] && wget -t 3 -T 30 -O dl/u-boot-2024.10.tar.bz2 https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2
