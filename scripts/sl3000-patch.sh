#!/bin/bash
# File name: sl3000-patch.sh

# -----------------------------------------------------------------------------
# 物理修复 1：解决 feed 冲突
# -----------------------------------------------------------------------------
sed -i '/helloworld/d' feeds.conf.default
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# -----------------------------------------------------------------------------
# 物理修复 2：硬件补丁注入 (锁定 1GB RAM)
# -----------------------------------------------------------------------------
if [ -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" ]; then
    cp -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/ 2>/dev/null
    mkdir -p target/linux/mediatek/dts/mediatek/
    cp -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/mediatek/
fi

if [ -f "$GITHUB_WORKSPACE/custom-config/filogic.mk" ]; then
    cp -f "$GITHUB_WORKSPACE/custom-config/filogic.mk" target/linux/mediatek/image/filogic.mk
fi

# -----------------------------------------------------------------------------
# 物理修复 3：mt76 预处理 (防止 autoconf.h 报错)
# -----------------------------------------------------------------------------
# 物理更新 mt76 时间戳，强迫编译器在处理它之前必须先对齐依赖
find package/kernel/mt76 -name "Makefile" -exec touch {} +

# -----------------------------------------------------------------------------
# 物理修复 4：强制开启 U-Boot 生成开关与设备锁定
# -----------------------------------------------------------------------------
if [ -f ".config" ]; then
    sed -i '/CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc/d' .config
    sed -i '/CONFIG_PACKAGE_mt7981-bl2-emmc/d' .config
    sed -i '/CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc/d' .config
    
    echo "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y" >> .config
    echo "CONFIG_PACKAGE_mt7981-bl2-emmc=y" >> .config
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
fi

# 默认 IP 锁定
[ -f package/base-files/files/bin/config_generate ] && \
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate
