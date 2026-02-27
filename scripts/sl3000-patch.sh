#!/bin/bash
# File: scripts/sl3000-patch.sh

# 1. 三件套路径物理同步 (延续原文)
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

[ -f "custom-config/mt7981b-3000-emmc.dts" ] && cp -f "custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "custom-config/filogic.mk" ] && cp -f "custom-config/filogic.mk" "$MK_DEST"

# 2. 物理清零：彻底粉碎残留索引 (彻底解决 leading whitespace 警告)
# 物理删除 tmp 目录，强迫 OpenWrt 重新扫描源码目录
rm -rf tmp
rm -f .config.old

# 3. 物理屏蔽：彻底从 Makefile 移除 ASR3000 段落 (物理断绝其固件生成路径)
sed -i '/Device\/abt_asr3000/,/endef/d' target/linux/mediatek/image/filogic.mk

# 4. 物理修正 IP (192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 5. 物理补全：基于 6 行精简配置强制重新生成 .config
# 此时生成的 .config 将是纯净无误的，且 100% 包含 U-Boot
make defconfig
