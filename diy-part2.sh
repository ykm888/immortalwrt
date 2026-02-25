#!/bin/bash
#
# File name: diy-part2.sh
# 终极修复：最高级别物理毁灭干扰源 + 基因强制重组
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

# --- [最高级别物理手术：毁灭与重组] ---

# 1. 物理毁灭：直接删除造成干扰的 mt7622 (R64) 整个 Target 目录，让系统物理找不到它
# 这是解决漂移的最强物理手段
rm -rf target/linux/mediatek/mt7622
rm -rf target/linux/mediatek/image/mt7622.mk

# 2. 物理清场：删除 .config 中所有 Target 相关行
if [ -f .config ]; then
    sed -i '/CONFIG_TARGET_mediatek/d' .config
    sed -i '/CONFIG_TARGET_BOARD/d' .config
    sed -i '/CONFIG_TARGET_SUBTARGET/d' .config
    sed -i '/CONFIG_TARGET_PROFILE/d' .config
    sed -i '/CONFIG_TARGET_DEVICE/d' .config
    
    # 3. 基因强插：在文件第 1 行注入 SL-3000 绝对指令（物理最高优先级）
    # 强制锁定 1GB 内存、EMMC 路径及 U-Boot
    sed -i '1i CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y\nCONFIG_HAS_SUBTARGET_FILOGIC=y\nCONFIG_TARGET_BOARD="mediatek"\nCONFIG_TARGET_SUBTARGET="filogic"\nCONFIG_TARGET_PROFILE="DEVICE_sl_3000-emmc"\nCONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y\nCONFIG_HIGHMEM=y\nCONFIG_TARGET_OPTIONS=y\nCONFIG_TARGET_RAM_OPTIMIZE=y' .config

    # 4. 物理修复 OpenSSL 冲突
    sed -i 's/CONFIG_PACKAGE_libopenssl-afalg_sync=y/# CONFIG_PACKAGE_libopenssl-afalg_sync is not set/g' .config
    
    # 5. 物理粉碎低内存基因，锁定 1GB
    sed -i 's/CONFIG_LOW_MEM_256M=y/# CONFIG_LOW_MEM_256M is not set/g' .config
fi

# 物理源码补齐 (U-Boot 2024.10)
[ ! -f "dl/u-boot-2024.10.tar.bz2" ] && wget -t 3 -T 30 -O dl/u-boot-2024.10.tar.bz2 https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2
