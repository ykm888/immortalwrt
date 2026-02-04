#!/bin/bash
set -e

echo ">>> [SL3000-Final-Logic] 正在同步 1GB 物理配置..."

# 1. 环境劫持 (解决 m4 报错)
mkdir -p staging_dir/host/bin
ln -sf /usr/bin/m4 staging_dir/host/bin/m4
ln -sf /usr/bin/flex staging_dir/host/bin/flex
ln -sf /usr/bin/bison staging_dir/host/bin/bison
touch staging_dir/host/.tools_install_y

# 2. 自动定位自定义配置目录 (使用绝对路径)
# $GITHUB_WORKSPACE 是 GitHub Actions 的内置变量
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

# 3. 核心文件注入 (增加存在性检查)
[ -f "$SRC_DIR/sl3000_defconfig" ] && cp -fv "$SRC_DIR/sl3000_defconfig" .config || echo "⚠️ Warning: sl3000_defconfig not found"
[ -f "$SRC_DIR/filogic.mk" ] && cp -fv "$SRC_DIR/filogic.mk" target/linux/mediatek/image/filogic.mk || echo "⚠️ Warning: filogic.mk not found"

# 4. 建立 DTS 绝对路径备份 (供后续步骤使用)
mkdir -p "${GITHUB_WORKSPACE}/fixed_files"
cp -fv "$SRC_DIR/mt7981b-sl3000-emmc.dts" "${GITHUB_WORKSPACE}/fixed_files/sl3000.dts"

# 5. 更新 Feeds
./scripts/feeds update -a && ./scripts/feeds install -a
make defconfig
