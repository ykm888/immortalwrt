#!/bin/bash
# File: scripts/sl3000-patch.sh
# 物理修复：针对救砖需求，强制产出底层固件，彻底解决 BL2 缺失问题

# 1. 物理注入 DTS 和 MK (原文照抄逻辑)
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"
if [ -f "../custom-config/mt7981b-sl-3000-emmc.dts" ]; then
    cp -f ../custom-config/mt7981b-sl-3000-emmc.dts "$DTS_DEST/mt7981b-sl-3000-emmc.dts"
fi

# 2. 物理注入 MK 配置 (确保 U-Boot/FIP 生成逻辑)
if [ -f "../custom-config/filogic.mk" ]; then
    cp -f ../custom-config/filogic.mk "$MK_DEST"
fi

# 3. 原文照抄：修改默认管理 IP
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 4. 物理身份锁死与救砖组件强制注入 (解决 BL2 缺失报错)
if [ -f .config ]; then
    # 物理移除旧版内核残留
    sed -i '/CONFIG_LINUX_5_4/d' .config
    # 物理注入核心架构定义
    sed -i '1i CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y' .config
    
    # [物理修复点] 强制追加救砖组件配置
    cat >> .config <<EOF
CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-comb=y
CONFIG_PACKAGE_trusted-firmware-a-mt7981-sdmmc-comb=y
CONFIG_PACKAGE_uboot-mtk-sl_3000-emmc=y
CONFIG_PACKAGE_uboot-envtool=y
EOF
fi

# 5. 物理依赖补齐：强制安装并对齐 ATF 源码包
./scripts/feeds install -a
./scripts/feeds install trusted-firmware-a-mt7981

echo "物理补丁执行完毕：配置已物理锁定。"
