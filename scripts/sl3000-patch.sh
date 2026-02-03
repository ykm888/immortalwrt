#!/bin/bash
set -e

echo ">>> [SL3000 Final] 正在同步 1GB 扩容配置..."

ROOT_DIR=$(pwd)
# 自动定位仓库根目录（兼容 GitHub Actions 环境）
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(cd ..; pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

# --- 1. 环境劫持 (解决 m4 报错) ---
mkdir -p staging_dir/host/bin
ln -sf /usr/bin/m4 staging_dir/host/bin/m4
ln -sf /usr/bin/flex staging_dir/host/bin/flex
ln -sf /usr/bin/bison staging_dir/host/bin/bison
ln -sf /usr/bin/flex staging_dir/host/bin/lex
touch staging_dir/host/.tools_install_y
mkdir -p staging_dir/host/stamp
touch staging_dir/host/stamp/.tools_compile_y
touch staging_dir/host/stamp/.m4_installed

# --- 2. 物理文件同步 (核心) ---
# 同步 .config (来自你的 sl3000_defconfig)
if [ -f "$SRC_DIR/sl3000_defconfig" ]; then
    cp -fv "$SRC_DIR/sl3000_defconfig" .config
else
    echo "❌ 错误: 找不到 custom-config/sl3000_defconfig" && exit 1
fi

# 同步 filogic.mk (决定 1GB 大小)
if [ -f "$SRC_DIR/filogic.mk" ]; then
    cp -fv "$SRC_DIR/filogic.mk" target/linux/mediatek/image/filogic.mk
else
    echo "❌ 错误: 找不到 custom-config/filogic.mk" && exit 1
fi

# --- 3. DTS 物理缝合 (注入 1GB 内存定义) ---
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)
INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"
DTS_SRC="$SRC_DIR/mt7981b-sl3000-emmc.dts"

{
    echo '/dts-v1/;'
    grep "#include" "$BASE_DTSI" | head -n 20
    echo '#include <dt-bindings/leds/common.h>'
    echo '#include <dt-bindings/input/input.h>'
    sed -E '/\/dts-v1\/;|#include/d' "$BASE_DTSI"
    [ -f "$INC_DIR/mt7981b.dtsi" ] && sed -E '/\/dts-v1\/;|#include/d' "$INC_DIR/mt7981b.dtsi"
    echo -e "\n/* --- SL3000 CUSTOM SECTION --- */\n"
    tr -d '\r' < "$DTS_SRC" | sed -E '/\/dts-v1\/;|#include|mt7981.dtsi/d'
} > "$DTS_DEST"

# --- 4. 刷新 Feeds 并锁定配置 ---
./scripts/feeds update -a && ./scripts/feeds install -a
make defconfig
echo "✅ [脚本完成] 劫持与 1GB 配置注入已就绪。"
