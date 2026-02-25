#!/bin/bash
# File: scripts/sl3000-patch.sh
# 物理修复：全路径死锁方案 (含 target/linux/mediatek/dts)

# --- [原文照抄：成功案例逻辑] ---
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# --- [物理修复：ebtables 补齐] ---
mkdir -p dl
EBT_FILE="ebtables-2018.06.27~48cff25d.tar.zst"
if [ ! -f "dl/$EBT_FILE" ]; then
    wget -t 3 -T 30 -O "dl/$EBT_FILE" "https://sources.openwrt.org/$EBT_FILE"
fi

# --- [最高级别物理毁灭：铲除 R64] ---
rm -rf target/linux/mediatek/mt7622
rm -rf target/linux/mediatek/image/mt7622.mk

# --- [物理路径全覆盖：精准锁定所有 DTS 可能路径] ---
# 包含用户指定的 target/linux/mediatek/dts 路径
DTS_PATHS=(
    "target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
    "target/linux/mediatek/dts"
)

for target_path in "${DTS_PATHS[@]}"; do
    mkdir -p "$target_path"
    # 物理注入：同时覆盖原生名称和系统识别名
    cp -f ../custom-config/mt7981b-3000-emmc.dts "$target_path/mt7981b-sl-3000-emmc.dts" 2>/dev/null
    cp -f ../custom-config/mt7981b-3000-emmc.dts "$target_path/mt7981b-3000-emmc.dts" 2>/dev/null
done

# 物理注入镜像定义
cp -f ../custom-config/filogic.mk target/linux/mediatek/image/filogic.mk 2>/dev/null

# --- [物理基因锁死：.config 圣旨模式] ---
if [ -f .config ]; then
    # 物理清场
    sed -i '/CONFIG_TARGET_mediatek/d' .config
    sed -i '/CONFIG_TARGET_BOARD/d' .config
    sed -i '/CONFIG_TARGET_SUBTARGET/d' .config
    sed -i '/CONFIG_TARGET_PROFILE/d' .config
    sed -i '/CONFIG_TARGET_DEVICE/d' .config
    
    # 物理插队：强制声明 1GB 内存及 SL-3000 身份
    sed -i '1i CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y\nCONFIG_HAS_SUBTARGET_FILOGIC=y\nCONFIG_TARGET_BOARD="mediatek"\nCONFIG_TARGET_SUBTARGET="filogic"\nCONFIG_TARGET_PROFILE="DEVICE_sl_3000-emmc"\nCONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y\nCONFIG_HIGHMEM=y' .config

    # 物理修复冲突
    sed -i 's/CONFIG_PACKAGE_libopenssl-afalg_sync=y/# CONFIG_PACKAGE_libopenssl-afalg_sync is not set/g' .config
fi

# 物理源码补齐 (U-Boot 2024.10)
[ ! -f "dl/u-boot-2024.10.tar.bz2" ] && wget -t 3 -T 30 -O dl/u-boot-2024.10.tar.bz2 https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2
