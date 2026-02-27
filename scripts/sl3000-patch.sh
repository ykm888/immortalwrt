#!/bin/bash
# File: scripts/sl3000-patch.sh

# 1. 三件套路径物理同步
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

[ -f "custom-config/mt7981b-3000-emmc.dts" ] && cp -f "custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "custom-config/filogic.mk" ] && cp -f "custom-config/filogic.mk" "$MK_DEST"

# 2. 物理屏蔽：彻底删除 ASR3000 定义
sed -i '/Device\/abt_asr3000/,/endef/d' target/linux/mediatek/image/filogic.mk

# 3. 物理修正 IP (192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 4. 物理激活：基于精简配置自动补全
make defconfig
