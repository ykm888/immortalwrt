#!/bin/bash
# File: scripts/sl3000-patch.sh

# 1. 三件套路径物理同步
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

[ -f "custom-config/mt7981b-3000-emmc.dts" ] && cp -f "custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "custom-config/filogic.mk" ] && cp -f "custom-config/filogic.mk" "$MK_DEST"

# 2. 物理彻底清零 (解决 leading whitespace 警告的终极手段)
# 物理强制删除 tmp 目录和旧配置索引，让系统彻底忘记那 8000 行旧记忆
rm -rf tmp
rm -f .config.old

# 3. 物理屏蔽：彻底从 Makefile 逻辑中抹除 ASR3000，让 ImageBuilder 无法生成它
sed -i '/Device\/abt_asr3000/,/endef/d' target/linux/mediatek/image/filogic.mk

# 4. 物理修正 IP (192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 5. 物理激活：强制基于精简 Config 重新补全依赖
# 这一步会根据您的 6 行核心配置，物理拉取所有 SL-3000 必需的 Wi-Fi 和驱动插件
make defconfig
