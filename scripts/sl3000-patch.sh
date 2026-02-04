#!/bin/bash
# =================================================================
# SL3000 Factory Edition - Brute Force Source Remaker (V2.0)
# =================================================================
set -e

[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ../; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

echo "🚀 [Step 1/3] 正在净化硬件基因并物理注入..."

# 1. 注入镜像生成规则 (决定 1000M 布局)
mkdir -p target/linux/mediatek/image
cp -fv "$SRC_DIR/filogic.mk" target/linux/mediatek/image/filogic.mk

# 2. 暴力净化并注入 DTS
# 逻辑：确保 Unix 换行符，确保只有一行 /dts-v1/;，防止语法报错
mkdir -p target/linux/mediatek/dts
DTS_TMP="target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts"

{
    echo '/dts-v1/;'
    grep -v "/dts-v1/;" "$SRC_DIR/mt7981b-sl3000-emmc.dts" | tr -d '\r'
} > "$DTS_TMP"

# 3. 宿主机工具链硬链接 (暴力解决 m4/flex 报错)
echo "🚀 [Step 2/3] 劫持宿主机工具链..."
mkdir -p staging_dir/host/bin
for tool in m4 flex bison lex; do
    ln -sf /usr/bin/$tool staging_dir/host/bin/$tool
done
touch staging_dir/host/.tools_install_y
mkdir -p staging_dir/host/stamp
touch staging_dir/host/stamp/.tools_compile_y

# 4. 同步 Feeds 并应用配置
echo "🚀 [Step 3/3] 正在强制刷新 Feeds 与菜单配置..."
./scripts/feeds update -a && ./scripts/feeds install -a
cp -fv "$SRC_DIR/sl3000_defconfig" .config
make defconfig

echo "✅ 源码树已暴力重构，基因净化完成。"
