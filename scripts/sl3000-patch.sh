#!/bin/bash
# File: scripts/sl3000-patch.sh
# 物理修复：强制创建缺失的 files 路径并注入 U-Boot 配置文件

MAKEFILE="package/boot/uboot-mediatek/Makefile"

# 1. 物理注入 U-Boot 设备定义块
if [ -f "$MAKEFILE" ] && ! grep -q "mt7981_sl_3000-emmc" "$MAKEFILE"; then
    cat >> "$MAKEFILE" <<EOF

define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL 3000 (eMMC)
  BUILD_SUBTARGET:=filogic
  BUILD_DEVICES:=sl_3000-emmc
  UBOOT_CONFIG:=mt7981_sl_3000-emmc
  UBOOT_IMAGE:=u-boot.fip
  BL2_BOOTDEV:=emmc
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr3
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr3
endef
EOF
    sed -i '/UBOOT_TARGETS :=/a \	mt7981_sl_3000-emmc \\' "$MAKEFILE"
fi

# 2. 物理修复：强制递归创建缺失的 files/configs 路径 (彻底解决目录不存在问题)
UBOOT_FILES_DIR="package/boot/uboot-mediatek/files/configs"
mkdir -p "$UBOOT_FILES_DIR"

# 3. 物理注入缺失的 mt7981_sl_3000-emmc_defconfig
cat > "$UBOOT_FILES_DIR/mt7981_sl_3000-emmc_defconfig" <<EOF
CONFIG_ARM=y
CONFIG_SYS_ARCH_TIMER=y
CONFIG_ARCH_MEDIATEK=y
CONFIG_SYS_MALLOC_F_LEN=0x4000
CONFIG_SYS_HAS_NONCACHED_MEMORY=y
CONFIG_TARGET_MT7981=y
CONFIG_DEBUG_UART_BASE=0x11002000
CONFIG_DEBUG_UART_CLOCK=40000000
CONFIG_SYS_LOAD_ADDR=0x44000000
CONFIG_DEBUG_UART=y
CONFIG_DEFAULT_DEVICE_TREE="mt7981-mediatek-7981r128"
EOF

# 4. 原文照抄原则：物理同步 DTS/MK/IP
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"
[ -f "../custom-config/mt7981b-sl-3000-emmc.dts" ] && cp -f ../custom-config/mt7981b-sl-3000-emmc.dts "$DTS_DEST/mt7981b-sl-3000-emmc.dts"
[ -f "../custom-config/filogic.mk" ] && cp -f ../custom-config/filogic.mk "$MK_DEST"
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 5. 物理配置锁定 (.config 强制注入)
if [ -f .config ]; then
    sed -i '/CONFIG_LINUX_5_4/d' .config
    sed -i '1i CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y' .config
    cat >> .config <<EOF
CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-ddr3=y
CONFIG_PACKAGE_uboot-mediatek-mt7981_sl_3000-emmc=y
EOF
fi

echo "物理修复完成：已强制创建 files 目录并注入补丁。"
