#!/bin/bash
# File: scripts/sl3000-patch.sh

# 1. 三件套路径物理同步 (延续原文)
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

[ -f "custom-config/mt7981b-3000-emmc.dts" ] && cp -f "custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "custom-config/filogic.mk" ] && cp -f "custom-config/filogic.mk" "$MK_DEST"

# 2. 物理清道夫：粉碎旧的 8000 行残留索引 (解决 warning: leading whitespace 的根源)
rm -rf tmp
rm -f .config.old

# 3. 物理屏蔽：彻底从 Makefile 移除 ASR3000 逻辑段
sed -i '/Device\/abt_asr3000/,/endef/d' target/linux/mediatek/image/filogic.mk

# 4. 物理修正 IP (192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 5. 物理激活：基于您的精简版 Config 强制重新补全所有驱动
# 执行此步后，系统会重新生成干净的 tmp 目录
make defconfig
