#!/bin/bash
# File: scripts/sl3000-patch.sh

# 1. 物理路径对齐
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"
[ -f "custom-config/mt7981b-3000-emmc.dts" ] && cp -f "custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "custom-config/filogic.mk" ] && cp -f "custom-config/filogic.mk" "$MK_DEST"

# 2. 终极物理重置：粉碎残留索引缓存
# 彻底解决 leading whitespace 警告的死穴：必须删除 tmp
rm -rf tmp
rm -f .config.old

# 3. 物理切断：抹除 ASR3000 干扰段
sed -i '/Device\/abt_asr3000/,/endef/d' target/linux/mediatek/image/filogic.mk

# 4. 物理修正 IP
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 5. 物理锁定：强制重新生成纯净的配置索引
make defconfig

echo "24.10 源码 + 6.6 内核 物理环境彻底重置完毕，缓存已清空。"
