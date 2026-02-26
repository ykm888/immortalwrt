#!/bin/bash
# File: scripts/sl3000-patch.sh
# 物理修复：在本地克隆的代码树中物理注入缺失的 U-Boot 定义

MAKEFILE="package/boot/uboot-mediatek/Makefile"

# 1. 物理注入 U-Boot 设备定义块 (修复 No rule to make target 报错)
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

    # 物理追加到目标编译列表 UBOOT_TARGETS
    sed -i '/UBOOT_TARGETS :=/a \	mt7981_sl_3000-emmc \\' "$MAKEFILE"
fi

# 2. 原文照抄：DTS、MK 及 IP 物理同步
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

# 物理同步 DTS 路径
if [ -f "../custom-config/mt7981b-sl-3000-emmc.dts" ]; then
    cp -f ../custom-config/mt7981b-sl-3000-emmc.dts "$DTS_DEST/mt7981b-sl-3000-emmc.dts"
fi

# 物理同步 MK 配置
if [ -f "../custom-config/filogic.mk" ]; then
    cp -f ../custom-config/filogic.mk "$MK_DEST"
fi

# 原文照抄：修改管理 IP 为 192.168.6.1
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 3. 物理配置锁定 (.config 强制注入)
if [ -f .config ]; then
    sed -i '/CONFIG_LINUX_5_4/d' .config
    sed -i '1i CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y' .config
    cat >> .config <<EOF
CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-ddr3=y
CONFIG_PACKAGE_uboot-mediatek-mt7981_sl_3000-emmc=y
EOF
fi

echo "脚本物理执行完毕：Makefile 定义已成功补齐。"
