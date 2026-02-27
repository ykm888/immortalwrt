#!/bin/bash
# File: scripts/sl3000-patch.sh

# 1. 三件套路径物理同步
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

[ -f "custom-config/mt7981b-3000-emmc.dts" ] && cp -f "custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "custom-config/filogic.mk" ] && cp -f "custom-config/filogic.mk" "$MK_DEST"

# 2. 物理暴力覆盖：强行开启 U-Boot 和 ATF 编译开关
# 逻辑：先删除已有定义，再强制注入，确保编译器必须执行 uboot-mediatek 步骤
if [ -f .config ]; then
    # 物理清除所有相关冲突行
    sed -i '/CONFIG_PACKAGE_uboot-mediatek/d' .config
    sed -i '/CONFIG_PACKAGE_trusted-firmware-a/d' .config
    
    # 物理死锁 SL-3000 救砖核心勾选
    echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-ddr3=y" >> .config
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl_3000-emmc=y" >> .config
    
    # 物理强制选中设备，防止 target 编译偏移
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
fi

# 3. 物理清理：防止 ASR3000 等无关配置文件干扰
find package/boot/uboot-mediatek/files/configs/ -type f -not -name "*sl_3000-emmc*" -delete 2>/dev/null || true

# 4. 修改默认 IP
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate
