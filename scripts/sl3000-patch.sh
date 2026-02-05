#!/bin/bash
set -e

[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ../; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

echo "🔥 [Step 1] 基因清洗与预注入..."

# 1. 镜像模具注入
mkdir -p target/linux/mediatek/image
cp -fv "$SRC_DIR/filogic.mk" target/linux/mediatek/image/filogic.mk

# 2. 彻底清洗 DTS (移除回车符，强制 Unix 格式)
mkdir -p target/linux/mediatek/dts
{
    echo '/dts-v1/;'
    grep -v "/dts-v1/;" "$SRC_DIR/mt7981b-sl3000-emmc.dts" | tr -d '\r'
} > target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts

# 3. 劫持宿主机工具链
mkdir -p staging_dir/host/bin
for tool in m4 flex bison lex; do
    ln -sf /usr/bin/$tool staging_dir/host/bin/$tool
done
touch staging_dir/host/.tools_install_y

# 4. 强制 Feeds 更新与配置注入
./scripts/feeds update -a && ./scripts/feeds install -a
cp -fv "$SRC_DIR/sl3000_defconfig" .config
make defconfig

echo "✅ 基础注入完成。"
