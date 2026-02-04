#!/bin/bash
set -e

echo ">>> [SL3000] 执行初始化注入..."

ROOT_DIR=$(pwd)
# 修正点：通过 find 动态获取配置仓库的绝对路径
SRC_DIR=$(find "${GITHUB_WORKSPACE}" -maxdepth 2 -type d -name "custom-config" | head -n 1)

DTS_SRC=$(find "$SRC_DIR" -type f -name "*mt7981b-sl3000-emmc.dts" | head -n 1)
MK_SRC=$(find "$SRC_DIR" -type f -name "filogic.mk" | head -n 1)

# --- 1. 依赖欺骗 ---
mkdir -p staging_dir/host/bin
ln -sf /usr/bin/m4 staging_dir/host/bin/m4
ln -sf /usr/bin/flex staging_dir/host/bin/flex
ln -sf /usr/bin/bison staging_dir/host/bin/bison
ln -sf /usr/bin/flex staging_dir/host/bin/lex
touch staging_dir/host/.tools_install_y
mkdir -p staging_dir/host/stamp
touch staging_dir/host/stamp/.tools_compile_y
touch staging_dir/host/.m4_installed

# --- 2. DTS 物理缝合 ---
BASE_DTSI=$(find "$ROOT_DIR/target/linux/mediatek" -name "mt7981.dtsi" | head -n 1)
INC_DIR=$(dirname "$BASE_DTSI")
DTS_DEST="$INC_DIR/mt7981b-sl3000-emmc.dts"

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

# --- 3. 注入配置 ---
./scripts/feeds update -a && ./scripts/feeds install -a
[ -f "$MK_SRC" ] && cp -fv "$MK_SRC" "target/linux/mediatek/image/filogic.mk"

cat <<EOT > .config
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y
CONFIG_TARGET_KERNEL_PARTSIZE=128
CONFIG_TARGET_ROOTFS_PARTSIZE=1024
CONFIG_PACKAGE_kmod-mmc=y
CONFIG_PACKAGE_kmod-sdhci-mtk=y
CONFIG_PACKAGE_f2fs-tools=y
CONFIG_PACKAGE_kmod-fs-f2fs=y
EOT

make defconfig
echo "✅ [脚本完成]"
