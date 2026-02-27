#!/bin/bash
# File: scripts/sl3000-patch.sh

echo "开始执行终极物理修复整合脚本..."

# 1. 物理重置环境：彻底粉碎残留索引 (解决 whitespace 警告的核心)
# 在同步任何文件前，先让系统“失忆”
rm -rf tmp
rm -f .config .config.old

# 2. 三件套路径物理同步 (原文照抄路径)
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

[ -f "../custom-config/mt7981b-3000-emmc.dts" ] && cp -f "../custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "../custom-config/filogic.mk" ] && cp -f "../custom-config/filogic.mk" "$MK_DEST"
[ -f "../custom-config/sl3000.config" ] && cp -f "../custom-config/sl3000.config" ".config"

# 3. 物理切断：抹除 ASR3000 硬件定义块，防止污染
sed -i '/Device\/abt_asr3000/,/endef/d' target/linux/mediatek/image/filogic.mk

# 4. 物理修正默认 IP (192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 5. 强制物理重扫：确保所有驱动 (含 U-Boot) 被重新识别
make defconfig

echo "整合脚本执行完毕，缓存已粉碎，SL-3000 配置已锁定。"
