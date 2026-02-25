#!/bin/bash
# 物理修复：针对成功案例仓库的最高级别路径锁定与干扰源物理毁灭
# 路径：scripts/sl3000-patch.sh

# --- [原文照抄：成功案例逻辑] ---
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# --- [物理修复：ebtables 源码补齐] ---
mkdir -p dl
EBT_FILE="ebtables-2018.06.27~48cff25d.tar.zst"
if [ ! -f "dl/$EBT_FILE" ]; then
    wget -t 3 -T 30 -O "dl/$EBT_FILE" "https://sources.openwrt.org/$EBT_FILE"
fi

# --- [物理锁定：精准对位 6.6 内核与三件套补丁] ---
# 物理确保自定义配置覆盖仓库原生定义
mkdir -p target/linux/mediatek/dts/
cp -f ../custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts 2>/dev/null
cp -f ../custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/ 2>/dev/null
cp -f ../custom-config/filogic.mk target/linux/mediatek/image/filogic.mk 2>/dev/null

# --- [最高级别物理毁灭：铲除 R64 干扰源] ---
# 既然系统默认选它，我们就物理删掉它，让它在物理层面不存在
rm -rf target/linux/mediatek/mt7622
rm -rf target/linux/mediatek/image/mt7622.mk

# --- [最高级别物理锁定：.config 基因插队手术] ---
if [ -f .config ]; then
    # 1. 物理清场：彻底粉碎所有 Target/Subtarget/Profile 定义
    sed -i '/CONFIG_TARGET_mediatek/d' .config
    sed -i '/CONFIG_TARGET_BOARD/d' .config
    sed -i '/CONFIG_TARGET_SUBTARGET/d' .config
    sed -i '/CONFIG_TARGET_PROFILE/d' .config
    sed -i '/CONFIG_TARGET_DEVICE/d' .config
    
    # 2. 物理插队：在文件首行注入最高优先级 SL-3000 指令 (圣旨模式)
    # 强制锁定 1GB 内存、EMMC 路径及 U-Boot 核心项
    sed -i '1i CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y\nCONFIG_HAS_SUBTARGET_FILOGIC=y\nCONFIG_TARGET_BOARD="mediatek"\nCONFIG_TARGET_SUBTARGET="filogic"\nCONFIG_TARGET_PROFILE="DEVICE_sl_3000-emmc"\nCONFIG_PACKAGE_mt7981-atf-mtk-uboot-ls-emmc=y\nCONFIG_HIGHMEM=y\nCONFIG_TARGET_OPTIONS=y\nCONFIG_TARGET_RAM_OPTIMIZE=y' .config

    # 3. 物理修复 OpenSSL 冲突
    sed -i 's/CONFIG_PACKAGE_libopenssl-afalg_sync=y/# CONFIG_PACKAGE_libopenssl-afalg_sync is not set/g' .config
    
    # 4. 锁定 1GB 内存，粉碎 512MB 限制
    sed -i 's/CONFIG_LOW_MEM_256M=y/# CONFIG_LOW_MEM_256M is not set/g' .config
fi

# 物理源码补齐 (U-Boot 2024.10)
[ ! -f "dl/u-boot-2024.10.tar.bz2" ] && wget -t 3 -T 30 -O dl/u-boot-2024.10.tar.bz2 https://ftp.denx.de/pub/u-boot/u-boot-2024.10.tar.bz2
