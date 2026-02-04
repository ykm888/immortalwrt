#!/bin/bash
# =================================================================
# SL3000 Flagship Edition - Source Remaker
# =================================================================
set -e

echo "🚀 [旗舰版] 正在构建专属源码树..."

# 1. 路径锚定
ROOT_DIR=$(pwd)
# 确保在 GitHub Actions 中能找到原始仓库路径
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ../; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

# 2. 物理劫持工具链 (防 unknown terminal 报错)
mkdir -p staging_dir/host/bin
ln -sf /usr/bin/m4 staging_dir/host/bin/m4
ln -sf /usr/bin/flex staging_dir/host/bin/flex
ln -sf /usr/bin/bison staging_dir/host/bin/bison
touch staging_dir/host/.tools_install_y

# 3. 注入镜像打包规则 (1GB 限制锁定)
mkdir -p target/linux/mediatek/image
cp -fv "$SRC_DIR/filogic.mk" target/linux/mediatek/image/filogic.mk

# 4. 注入设备树源文件
mkdir -p target/linux/mediatek/dts
cp -fv "$SRC_DIR/mt7981b-sl3000-emmc.dts" target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts

# 5. 注入预设菜单配置
cp -fv "$SRC_DIR/sl3000_defconfig" .config

# 6. 同步插件并强制刷新配置
./scripts/feeds update -a && ./scripts/feeds install -a
make defconfig

echo "✅ 源码树重构完成，SL3000 基因已注入。"
