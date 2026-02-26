#!/bin/bash
# File: scripts/sl3000-patch.sh
# 物理修复：动态注入 U-Boot 定义并执行环境物理清理

MAKEFILE="package/boot/uboot-mediatek/Makefile"

# 1. 物理注入 U-Boot 设备定义块 (彻底解决 No rule 报错)
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

    # 物理追加到目标编译列表
    sed -i '/UBOOT_TARGETS :=/a \	mt7981_sl_3000-emmc \\' "$MAKEFILE"
fi

# 2. 原文照抄原则：物理同步 DTS/MK/IP
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"
[ -f "../custom-config/mt7981b-sl-3000-emmc.dts" ] && cp -f ../custom-config/mt7981b-sl-3000-emmc.dts "$DTS_DEST/mt7981b-sl-3000-emmc.dts"
[ -f "../custom-config/filogic.mk" ] && cp -f ../custom-config/filogic.mk "$MK_DEST"
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 3. 物理配置锁定 (清理旧版内核残留，防止 Toolchain 识别错误)
if [ -f .config ]; then
    sed -i '/CONFIG_LINUX_5_4/d' .config
    sed -i '1i CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y' .config
    cat >> .config <<EOF
CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-ddr3=y
CONFIG_PACKAGE_uboot-mediatek-mt7981_sl_3000-emmc=y
EOF
fi

echo "物理补丁执行完毕：Makefile 定义注入 & 配置锁定。"
