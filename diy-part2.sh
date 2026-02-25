#!/bin/bash
#
# File name: diy-part2.sh
# 物理修复：强制锁定 SL-3000 (MT7981) 平台，防止误跳 R64
#

# --- [原文照抄：成功案例逻辑] ---
# 修改默认 IP
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# --- [物理修复：验证通过的 ebtables 源码补齐] ---
mkdir -p dl
EBT_FILE="ebtables-2018.06.27~48cff25d.tar.zst"
if [ ! -f "dl/$EBT_FILE" ]; then
    wget -t 3 -T 30 -O "dl/$EBT_FILE" "https://sources.openwrt.org/$EBT_FILE"
fi

# --- [物理对位：三件套硬件补丁注入] ---
cp -f ../custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mediatek/ 2>/dev/null
cp -f ../custom-config/filogic.mk target/linux/mediatek/image/filogic.mk 2>/dev/null

# --- [核心物理手术：锁定设备型号与 1GB 内存] ---
if [ -f .config ]; then
    # 1. 物理锁死 Target：移除所有可能导致跳转到 R64 的残余配置
    sed -i 's/CONFIG_TARGET_mediatek_mt7622=y/# CONFIG_TARGET_mediatek_mt7622 is not set/g' .config
    
    # 2. 物理注入 SL-3000 EMMC 身份锁定
    echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
    
    # 3. 物理修复 OpenSSL 冲突
    sed -i 's/CONFIG_PACKAGE_libopenssl-afalg_sync=y/# CONFIG_PACKAGE_libopenssl-afalg_sync is not set/g' .config
    
    # 4. 物理锁定 1GB 内存 (HIGHMEM)
    sed -i 's/CONFIG_LOW_MEM_256M=y/# CONFIG_LOW_MEM_256M is not set/g' .config
    echo "CONFIG_HIGHMEM=y" >> .config
    echo "CONFIG_TARGET_OPTIONS=y" >> .config
    echo "CONFIG_TARGET_RAM_OPTIMIZE=y" >> .config

    # 5. 物理锁定 U-Boot 构建目标 (ls-emmc)
    sed -i 's/.*CONFIG_PACKAGE_mt7981-atf-mtk-uboot-.*=n/CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y/g' .config
    echo "CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y" >> .config
fi

# 物理源码补齐 (U-Boot)
[ ! -f "dl/u-boot-2024.10.tar.bz2" ] && wget -t 3 -T 30 -O dl/u-boot-2024.10.tar.bz2 https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2
