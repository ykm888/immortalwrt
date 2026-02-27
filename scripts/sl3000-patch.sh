#!/bin/bash
# File: scripts/sl3000-patch.sh
# 物理修复：在本地代码树中物理注入 U-Boot 定义，严禁使用 EOF

MAKEFILE="package/boot/uboot-mediatek/Makefile"

# 1. 物理注入 U-Boot 设备定义块 (通过 printf 避开 EOF)
if [ -f "$MAKEFILE" ] && ! grep -q "mt7981_sl_3000-emmc" "$MAKEFILE"; then
    printf '\ndefine U-Boot/mt7981_sl_3000-emmc\n  NAME:=SL 3000 (eMMC)\n  BUILD_SUBTARGET:=filogic\n  BUILD_DEVICES:=sl_3000-emmc\n  UBOOT_CONFIG:=mt7981_sl_3000-emmc\n  UBOOT_IMAGE:=u-boot.fip\n  BL2_BOOTDEV:=emmc\n  BL2_SOC:=mt7981\n  BL2_DDRTYPE:=ddr3\n  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr3\nendef\n' >> "$MAKEFILE"
    
    # 物理追加到目标编译列表
    sed -i '/UBOOT_TARGETS :=/a \	mt7981_sl_3000-emmc \\' "$MAKEFILE"
fi

# 2. 物理建立缓冲路径并注入 defconfig (通过 printf 避开 EOF)
UBOOT_FILES_DIR="package/boot/uboot-mediatek/files/configs"
mkdir -p "$UBOOT_FILES_DIR"
printf 'CONFIG_ARM=y\nCONFIG_SYS_ARCH_TIMER=y\nCONFIG_ARCH_MEDIATEK=y\nCONFIG_SYS_MALLOC_F_LEN=0x4000\nCONFIG_SYS_HAS_NONCACHED_MEMORY=y\nCONFIG_TARGET_MT7981=y\nCONFIG_DEBUG_UART_BASE=0x11002000\nCONFIG_DEBUG_UART_CLOCK=40000000\nCONFIG_SYS_LOAD_ADDR=0x44000000\nCONFIG_DEBUG_UART=y\nCONFIG_DEFAULT_DEVICE_TREE="mt7981-mediatek-7981r128"\n' > "$UBOOT_FILES_DIR/mt7981_sl_3000-emmc_defconfig"

# 3. 原文照抄：DTS、MK 及 IP 物理同步
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"
[ -f "../custom-config/mt7981b-sl-3000-emmc.dts" ] && cp -f ../custom-config/mt7981b-sl-3000-emmc.dts "$DTS_DEST/mt7981b-sl-3000-emmc.dts"
[ -f "../custom-config/filogic.mk" ] && cp -f ../custom-config/filogic.mk "$MK_DEST"
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 4. 物理配置锁定 (.config)
if [ -f .config ]; then
    sed -i '/CONFIG_LINUX_5_4/d' .config
    sed -i '1i CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y' .config
    printf 'CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-ddr3=y\nCONFIG_PACKAGE_uboot-mediatek-mt7981_sl_3000-emmc=y\n' >> .config
fi

echo "脚本物理修复完成：已通过 printf 注入补丁。"
