#!/bin/bash
# File name: sl3000-patch.sh

# -----------------------------------------------------------------------------
# 物理修复 1：解决 Duplicate feed 'helloworld' 报错
# -----------------------------------------------------------------------------
sed -i '/helloworld/d' feeds.conf.default
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# -----------------------------------------------------------------------------
# 物理修复 2：硬件补丁注入 (路径对齐：小写 custom-config)
# -----------------------------------------------------------------------------

# 1. 物理注入 DTS (锁定 1GB RAM)
if [ -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" ]; then
    cp -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/ 2>/dev/null
    mkdir -p target/linux/mediatek/dts/mediatek/
    cp -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/mediatek/
fi

# 2. 物理覆盖 MK (彻底生成 U-Boot 的物理核心)
if [ -f "$GITHUB_WORKSPACE/custom-config/filogic.mk" ]; then
    cp -f "$GITHUB_WORKSPACE/custom-config/filogic.mk" target/linux/mediatek/image/filogic.mk
fi

# -----------------------------------------------------------------------------
# 物理修复 3：强行补齐 U-Boot 编译开关 (针对 8000 行配置缺失项)
# -----------------------------------------------------------------------------
if [ -f ".config" ]; then
    sed -i '/CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc/d' .config
    sed -i '/CONFIG_PACKAGE_mt7981-bl2-emmc/d' .config
    echo "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y" >> .config
    echo "CONFIG_PACKAGE_mt7981-bl2-emmc=y" >> .config
fi

# -----------------------------------------------------------------------------
# 物理修复 4：解决 mt76 编译冲突 (清理残余)
# -----------------------------------------------------------------------------
rm -rf package/kernel/mt76 package/kernel/mac80211

# -----------------------------------------------------------------------------
# 物理修复 5：默认 IP 锁定为 192.168.6.1
# -----------------------------------------------------------------------------
[ -f package/base-files/files/bin/config_generate ] && \
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate
