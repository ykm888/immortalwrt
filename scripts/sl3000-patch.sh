#!/bin/bash
# File: scripts/sl3000-patch.sh

# 1. 三件套路径物理同步 (延续成功案例)
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"
[ -f "custom-config/mt7981b-3000-emmc.dts" ] && cp -f "custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "custom-config/filogic.mk" ] && cp -f "custom-config/filogic.mk" "$MK_DEST"

# 2. 物理清零：粉碎残留索引 (彻底根除 whitespace 警告)
rm -rf tmp
rm -f .config.old

# 3. 物理屏蔽：彻底从 Makefile 抹除 ASR3000 定义段 (物理断绝其生成路径)
sed -i '/Device\/abt_asr3000/,/endef/d' target/linux/mediatek/image/filogic.mk

# 4. 物理修正 IP (192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 5. 物理补全：强制基于精简 Config 补齐底层依赖
make defconfig

echo "24.10 源码 + 6.6 内核 物理修复脚本执行完毕。"
