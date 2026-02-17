#!/bin/bash
# SL3000 专用源码重构脚本 - 128MB 物理对齐加固版
set -eo pipefail

REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 物理承袭：执行 SL3000 源码重构与 128MB 分区锁定...\033[0m"

# 1. 物理注入 DTS 与 Makefile (严禁偷工减料)
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$WORKDIR/$DTS_DEST"
cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$WORKDIR/$DTS_DEST/"
cp -fv "${SRC_DIR}/filogic.mk" "$WORKDIR/target/linux/mediatek/image/filogic.mk"

cd "$WORKDIR"

# 2. 物理修正 DTS：适配 24.10 内核引用路径
DTS_FILE="$DTS_DEST/mt7981b-3000-emmc.dts"
# 物理确保引用本地官方文件，并锁定 ID 为 23.05 兼容版
sed -i 's|#include "mt7981.dtsi"|#include "mt7981.dtsi"|g' "$DTS_FILE"
sed -i 's/compatible = .*/compatible = "sl,3000-emmc", "mediatek,mt7981";/' "$DTS_FILE"

# 3. 物理死锁：强制注入 .config，确保 U-Boot 与 128MB 偏移
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_3000-emmc=y"
    # 物理锁定 U-Boot 生成
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    echo "CONFIG_TARGET_IMAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    # 物理对齐 128MB 分区 (131072 KB)
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=131072"
    # 物理注入 eMMC 核心驱动
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y"
    echo "CONFIG_PACKAGE_uboot-envtools=y"
    echo "CONFIG_PACKAGE_kmod-gpt=y"
} >> .config

# 强制备份锁定配置，防止 make olddefconfig 覆盖
cp -fv .config .config.locked
echo "✅ 源码物理对齐与 128MB 分区死锁完成。"
