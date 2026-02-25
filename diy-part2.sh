#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
# 物理修复：移除 EOF，改用原生 echo 逐行锁定 SL-3000 硬件身份
#

# --- [原文照抄：成功案例逻辑] ---
# 修改默认 IP (192.168.1.1 -> 192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# --- [物理修复：验证通过的 ebtables 源码物理补齐] ---
mkdir -p dl
EBT_FILE="ebtables-2018.06.27~48cff25d.tar.zst"
if [ ! -f "dl/$EBT_FILE" ]; then
    wget -t 3 -T 30 -O "dl/$EBT_FILE" "https://sources.openwrt.org/$EBT_FILE"
fi

# --- [物理对位：三件套硬件补丁注入] ---
cp -f ../custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mediatek/ 2>/dev/null
cp -f ../custom-config/filogic.mk target/linux/mediatek/image/filogic.mk 2>/dev/null

# --- [终极物理锁死：使用原生 echo 强制锁定设备身份] ---
if [ -f .config ]; then
    # 1. 物理移除所有 mt7622/R64 相关的残余行
    sed -i '/TARGET_mediatek_mt7622/d' .config
    sed -i '/TARGET_DEVICE_mediatek_mt7622/d' .config
    sed -i '/TARGET_mediatek_mt7622_DEVICE_bpi_bananapi-r64/d' .config

    # 2. 物理注入 SL-3000 (MT7981) 锁定参数（禁用 EOF 模式）
    echo "CONFIG_TARGET_mediatek=y" >> .config
    echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
    echo "CONFIG_HAS_SUBTARGET_FILOGIC=y" >> .config
    echo "CONFIG_TARGET_BOARD=\"mediatek\"" >> .config
    echo "CONFIG_TARGET_SUBTARGET=\"filogic\"" >> .config
    echo "CONFIG_TARGET_PROFILE=\"DEVICE_sl_3000-emmc\"" >> .config
    echo "CONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y" >> .config
    echo "CONFIG_HIGHMEM=y" >> .config
    echo "CONFIG_TARGET_OPTIONS=y" >> .config
    echo "CONFIG_TARGET_RAM_OPTIMIZE=y" >> .config

    # 3. 物理修复 OpenSSL 冲突
    sed -i 's/CONFIG_PACKAGE_libopenssl-afalg_sync=y/# CONFIG_PACKAGE_libopenssl-afalg_sync is not set/g' .config
    
    # 4. 1GB 内存锁定
    sed -i 's/CONFIG_LOW_MEM_256M=y/# CONFIG_LOW_MEM_256M is not set/g' .config
fi

# 物理源码补齐 (U-Boot 2024.10)
[ ! -f "dl/u-boot-2024.10.tar.bz2" ] && wget -t 3 -T 30 -O dl/u-boot-2024.10.tar.bz2 https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2
