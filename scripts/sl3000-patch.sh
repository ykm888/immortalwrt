#!/bin/bash
# File: scripts/sl3000-patch.sh
# 物理修复：针对 6.6 内核路径执行像素级对位补丁

# 1. 物理注入 DTS (确保 1GB 内存配置物理命中)
# 仓库源路径对位：target/linux/mediatek/dts/
DTS_DEST="target/linux/mediatek/dts"
mkdir -p "$DTS_DEST"
if [ -f "../custom-config/mt7981b-sl-3000-emmc.dts" ]; then
    cp -f ../custom-config/mt7981b-sl-3000-emmc.dts "$DTS_DEST/mt7981b-sl-3000-emmc.dts"
fi

# 2. 物理注入 MK 配置 (确保 U-Boot 固件生成逻辑物理注入)
# 仓库源路径对位：target/linux/mediatek/image/filogic.mk
MK_DEST="target/linux/mediatek/image/filogic.mk"
if [ -f "../custom-config/filogic.mk" ]; then
    cp -f ../custom-config/filogic.mk "$MK_DEST"
fi

# 3. 原文照抄：修改默认管理 IP
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 4. 物理身份锁死：在 .config 首行强插目标设备
if [ -f .config ]; then
    sed -i '1i CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y' .config
fi

echo "物理补丁执行完毕，DTS 与 MK 已完成 6.6 分支对位。"
