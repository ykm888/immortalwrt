#!/bin/bash
# File name: sl3000-patch.sh
# 审计：此脚本在 openwrt 根目录下运行

# 1. 物理清场（仅针对 openwrt 内部编译残留，不删外部脚本）
echo "执行 OpenWrt 内部编译目录物理清场..."
rm -rf ./build_dir/target-*/linux-mediatek_filogic/mt76-*
rm -rf ./staging_dir/target-*/stamp/.package_kernel_mt76*
rm -rf ./tmp

# 2. 解决 feed 冲突
sed -i '/helloworld/d' feeds.conf.default 2>/dev/null
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# 3. 硬件补丁注入 (锁定 1GB RAM)
# 审计：绝对路径引用，物理对齐仓库文件
if [ -n "$GITHUB_WORKSPACE" ]; then
    if [ -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" ]; then
        cp -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/ 2>/dev/null
        mkdir -p target/linux/mediatek/dts/mediatek/
        cp -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/mediatek/
    fi
    if [ -f "$GITHUB_WORKSPACE/custom-config/filogic.mk" ]; then
        cp -f "$GITHUB_WORKSPACE/custom-config/filogic.mk" target/linux/mediatek/image/filogic.mk
    fi
fi

# 4. 【核心死锁】物理锁定 mt76 编译依赖
if [ -f package/kernel/mt76/Makefile ]; then
    sed -i 's/PKG_BUILD_DEPENDS:=/PKG_BUILD_DEPENDS:=mac80211 /g' package/kernel/mt76/Makefile
fi

# 5. IP 锁定 192.168.6.1
[ -f package/base-files/files/bin/config_generate ] && \
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate
