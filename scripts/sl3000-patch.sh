#!/bin/bash
# SL3000 专用源码重构脚本 (全链路自愈版)
set -eo pipefail

REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 执行全链路自愈：物理重构 SL3000 专用源码...\033[0m"

# 1. 物理注入核心组件
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$WORKDIR/$DTS_DEST"

# 物理校验：确保输入文件存在
[ -f "${SRC_DIR}/mt7981b-3000-emmc.dts" ] || { echo "❌ 缺失 DTS 文件"; exit 1; }
[ -f "${SRC_DIR}/filogic.mk" ] || { echo "❌ 缺失 Makefile 片段"; exit 1; }

cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$WORKDIR/$DTS_DEST/"
cp -fv "${SRC_DIR}/filogic.mk" "$WORKDIR/target/linux/mediatek/image/filogic.mk"

cd "$WORKDIR"

# 2. 自愈修复：DTS 路径与身份指纹
DTS_FILE="$DTS_DEST/mt7981b-3000-emmc.dts"
# 物理确保引用本地官方 .dtsi
sed -i 's|#include <arm64/mediatek/mt7981.dtsi>|#include "mt7981.dtsi"|g' "$DTS_FILE"
# 物理强制 Compatible 指纹对齐
sed -i 's/compatible = .*/compatible = "sl,3000-emmc", "mediatek,mt7981";/' "$DTS_FILE"

# 3. 物理锁定 .config (128MB 偏移与 U-Boot 强制生成)
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_3000-emmc=y"
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    echo "CONFIG_TARGET_IMAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=131072"
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y"
    echo "CONFIG_PACKAGE_uboot-envtools=y"
} >> .config

# 4. 物理压制：备份并刷新，防止构建时弹出配置选择框
cp -fv .config .config.locked
find target/linux/mediatek/ -name "*.dts*" -exec touch {} + || true

echo "✅ 源码物理对齐完成。"
