#!/bin/bash
# File name: sl3000-patch.sh
# 审计：此脚本已整合所有补丁逻辑，在 openwrt 根目录下执行

# --- 第一部分：Feeds 逻辑 (原 diy-part1 整合) ---
echo "执行 Feeds 物理合并修改..."
sed -i '/helloworld/d' feeds.conf.default 2>/dev/null
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# --- 第二部分：补丁逻辑 (原成功案例整合) ---

# 1. 物理清场（仅清理源码内部缓存）
rm -rf ./build_dir/target-*/linux-mediatek_filogic/mt76-*
rm -rf ./staging_dir/target-*/stamp/.package_kernel_mt76*
rm -rf ./tmp

# 2. 注入 1GB RAM 硬件补丁
# 审计：物理锁死 GITHUB_WORKSPACE 绝对路径进行覆盖
if [ -n "$GITHUB_WORKSPACE" ]; then
    echo "正在物理覆盖 SL3000 1GB 内存定义文件..."
    if [ -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" ]; then
        cp -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/ 2>/dev/null
        mkdir -p target/linux/mediatek/dts/mediatek/
        cp -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" target/linux/mediatek/dts/mediatek/
    fi
    if [ -f "$GITHUB_WORKSPACE/custom-config/filogic.mk" ]; then
        cp -f "$GITHUB_WORKSPACE/custom-config/filogic.mk" target/linux/mediatek/image/filogic.mk
    fi
fi

# 3. 【依赖死锁修复】物理锁定 mt76 编译顺序补丁 (延续修复成果)
if [ -f package/kernel/mt76/Makefile ]; then
    echo "执行 mt76 物理依赖死锁补丁..."
    sed -i 's/PKG_BUILD_DEPENDS:=/PKG_BUILD_DEPENDS:=mac80211 /g' package/kernel/mt76/Makefile
fi

# 4. IP 锁定 192.168.6.1 (延续修复成果)
echo "执行后台 IP 锁定：192.168.6.1..."
[ -f package/base-files/files/bin/config_generate ] && \
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate
