#!/bin/bash
# File: scripts/sl3000-patch.sh
# 物理修复：针对 6.6 内核路径执行像素级对位补丁，强制产出救砖底层固件

# 1. 物理注入 DTS (确保 1GB 内存配置物理命中)
DTS_DEST="target/linux/mediatek/dts"
mkdir -p "$DTS_DEST"
if [ -f "../custom-config/mt7981b-sl-3000-emmc.dts" ]; then
    cp -f ../custom-config/mt7981b-sl-3000-emmc.dts "$DTS_DEST/mt7981b-sl-3000-emmc.dts"
fi

# 2. 物理注入 MK 配置 (确保 U-Boot/FIP 固件生成逻辑物理注入)
MK_DEST="target/linux/mediatek/image/filogic.mk"
if [ -f "../custom-config/filogic.mk" ]; then
    cp -f ../custom-config/filogic.mk "$MK_DEST"
fi

# 3. 原文照抄：修改默认管理 IP
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 4. 物理身份锁死与救砖组件强制注入 (解决 BL2 缺失报错)
if [ -f .config ]; then
    # 物理移除 5.4 内核残留，防止架构锁死
    sed -i '/CONFIG_LINUX_5_4/d' .config
    
    # 物理注入核心架构定义（置于首行）
    sed -i '1i CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y' .config
    
    # 物理强制开启 TF-A (BL2) 和 U-Boot (FIP) 编译出口
    cat >> .config <<EOF
CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-comb=y
CONFIG_PACKAGE_trusted-firmware-a-mt7981-sdmmc-comb=y
CONFIG_PACKAGE_uboot-mtk-sl_3000-emmc=y
CONFIG_PACKAGE_uboot-envtool=y
EOF
fi

# 5. 物理依赖预装：确保源码树包含 TF-A 包定义
./scripts/feeds install trusted-firmware-a-mt7981

echo "物理补丁执行完毕：DTS/MK 已就绪，已物理强制开启底层救砖固件编译通道。"
