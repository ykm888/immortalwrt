#!/bin/bash
# File: scripts/sl3000-patch.sh

# 1. 三件套路径物理同步
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

# 物理对位：确保同步 custom-config 里的物理文件
[ -f "custom-config/mt7981b-3000-emmc.dts" ] && cp -f "custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "custom-config/filogic.mk" ] && cp -f "custom-config/filogic.mk" "$MK_DEST"

# 2. 物理勾选强制开关（针对 6.6 内核 U-Boot 编译）
if [ -f .config ]; then
    echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-ddr3=y" >> .config
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl_3000-emmc=y" >> .config
fi

# 3. 修改默认 IP
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate
