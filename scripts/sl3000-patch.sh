#!/bin/bash
# File name: sl3000-patch.sh

# -----------------------------------------------------------------------------
# 0. 【物理级全量清空】彻底删除全部缓存，抹除一切状态记录
# -----------------------------------------------------------------------------
echo "执行最高级别物理清场..."
rm -rf ./feeds ./feeds.conf ./feeds.conf.default
rm -rf ./build_dir ./staging_dir ./tmp
# 物理强杀隐藏状态戳，确保不再跳过修复逻辑
find ./ -name ".package_*" -delete
find ./ -name ".stamp_*" -delete
find ./ -name ".configured_*" -delete

# 1. 解决 feed 冲突
sed -i '/helloworld/d' feeds.conf.default 2>/dev/null
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# 2. 硬件补丁注入 (锁定 1GB RAM)
if [ -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" ]; then
    cp -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/ 2>/dev/null
    mkdir -p target/linux/mediatek/dts/mediatek/
    cp -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/mediatek/
fi
if [ -f "$GITHUB_WORKSPACE/custom-config/filogic.mk" ]; then
    cp -f "$GITHUB_WORKSPACE/custom-config/filogic.mk" target/linux/mediatek/image/filogic.mk
fi

# 3. 【核心加固】物理锁定编译顺序
# 强制让 mt76 依赖 mac80211，防止并行编译时 autoconf.h 缺失
[ -f package/kernel/mt76/Makefile ] && sed -i 's/PKG_BUILD_DEPENDS:=/PKG_BUILD_DEPENDS:=mac80211 /g' package/kernel/mt76/Makefile

# 4. 强制锁定 Profile 确保 U-Boot 生成
if [ -f ".config" ]; then
    sed -i '/CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc/d' .config
    sed -i '/CONFIG_PACKAGE_mt7981-bl2-emmc/d' .config
    sed -i '/CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc/d' .config
    echo "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y" >> .config
    echo "CONFIG_PACKAGE_mt7981-bl2-emmc=y" >> .config
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
fi

# 5. IP 锁定 192.168.6.1
[ -f package/base-files/files/bin/config_generate ] && \
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate
