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

# 4. 物理身份锁死：在 .config 注入目标设备及补齐 TF-A 编译项（物理修复 Error 1）
if [ -f .config ]; then
    # 物理移除 5.4 内核残留，防止架构锁死
    sed -i '/CONFIG_LINUX_5_4/d' .config
    
    # 注入核心架构定义
    sed -i '1i CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y' .config
    
    # [物理修复点] 强插 TF-A 编译开关，确保生成 mt7981-emmc-comb-bl2.img
    echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-comb=y" >> .config
    echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-sdmmc-comb=y" >> .config
    echo "CONFIG_PACKAGE_uboot-mtk-sl_3000-emmc=y" >> .config
fi

echo "物理补丁执行完毕：DTS/MK 已就绪，已物理补齐 TF-A/BL2 编译开关。"
