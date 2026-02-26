#!/bin/bash
# File: scripts/sl3000-patch.sh
# 物理修复：针对救砖需求，强制产出 BL2 和 FIP (U-Boot) 底层固件

# 1. 物理注入 DTS 和 MK (维持原文逻辑)
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"
[ -f "../custom-config/mt7981b-sl-3000-emmc.dts" ] && cp -f ../custom-config/mt7981b-sl-3000-emmc.dts "$DTS_DEST/"
[ -f "../custom-config/filogic.mk" ] && cp -f ../custom-config/filogic.mk "$MK_DEST"

# 2. 原文照抄：修改默认管理 IP
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 3. 物理救砖配置注入 (解决 Error 2 报错并开启底层固件生成)
if [ -f .config ]; then
    # 物理移除 5.4 内核残留，防止架构锁死
    sed -i '/CONFIG_LINUX_5_4/d' .config
    
    # 物理注入核心架构定义
    sed -i '1i CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y' .config
    
    # [救砖专用物理修复] 强制补齐 TF-A (BL2) 和 U-Boot (FIP) 的编译出口
    # 只有开启这些，编译生成的 bin 文件夹里才会有救砖用的 .bin 和 .fip 文件
    echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-comb=y" >> .config
    echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-sdmmc-comb=y" >> .config
    echo "CONFIG_PACKAGE_uboot-mtk-sl_3000-emmc=y" >> .config
    echo "CONFIG_PACKAGE_uboot-envtool=y" >> .config
fi

echo "物理补丁执行完毕：底层引导救砖固件已物理对位。"
