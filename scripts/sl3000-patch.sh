#!/bin/bash
set -e

echo ">>> [SL3000-Fixed] 正在同步 1GB 物理配置..."

ROOT_DIR=$(pwd)
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

# 1. 环境劫持
mkdir -p staging_dir/host/bin
ln -sf /usr/bin/m4 staging_dir/host/bin/m4
ln -sf /usr/bin/flex staging_dir/host/bin/flex
ln -sf /usr/bin/bison staging_dir/host/bin/bison
touch staging_dir/host/.tools_install_y

# 2. 核心文件注入
[ -f "$SRC_DIR/sl3000_defconfig" ] && cp -fv "$SRC_DIR/sl3000_defconfig" .config
[ -f "$SRC_DIR/filogic.mk" ] && cp -fv "$SRC_DIR/filogic.mk" target/linux/mediatek/image/filogic.mk

# --- [修复核心] ---
# 创建一个绝对安全的备份目录，不依赖 target 内部路径
mkdir -p "$ROOT_DIR/sl3000_fixed"
cp -fv "$SRC_DIR/mt7981b-sl3000-emmc.dts" "$ROOT_DIR/sl3000_fixed/sl3000.dts"

# 3. 刷新 Feeds
./scripts/feeds update -a && ./scripts/feeds install -a
make defconfig
echo "✅ 注入完成，DTS 已备份至 $ROOT_DIR/sl3000_fixed/"
