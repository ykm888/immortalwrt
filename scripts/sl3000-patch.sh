#!/bin/bash
# SL3000 专用源码重构脚本 - 128MB 物理对齐版
set -eo pipefail

REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 开始物理重构 SL3000 专用源码 (24.10 适配)...\033[0m"

# 1. 物理注入核心组件 (DTS 和 Makefile)
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$WORKDIR/$DTS_DEST"

cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$WORKDIR/$DTS_DEST/"
cp -fv "${SRC_DIR}/filogic.mk" "$WORKDIR/target/linux/mediatek/image/filogic.mk"

cd "$WORKDIR"

# 2. 物理修正 DTS 路径 (适配官方 24.10 源码结构)
DTS_FILE="$DTS_DEST/mt7981b-3000-emmc.dts"
if [ -f "$DTS_FILE" ]; then
    # 确保本地包含官方提供的 mt7981.dtsi
    sed -i 's|#include <arm64/mediatek/mt7981.dtsi>|#include "mt7981.dtsi"|g' "$DTS_FILE"
    # 强制身份指纹锁定
    sed -i 's/compatible = .*/compatible = "sl,3000-emmc", "mediatek,mt7981";/' "$DTS_FILE"
fi

# 3. 物理名称对齐：强制 Makefile 使用 3000-emmc ID
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/sl3000/3000-emmc/g' {} + || true

# 4. 物理锁定 .config：强制 128MB 偏移与 U-Boot 生成
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_3000-emmc=y"
    # 物理选中 U-Boot 编译
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    echo "CONFIG_TARGET_IMAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    # 物理锁定分区大小 (131072 KB = 128 MB)
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=131072"
    # 物理锁定 eMMC 必要驱动
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y"
    echo "CONFIG_PACKAGE_kmod-gpt=y"
    echo "CONFIG_PACKAGE_uboot-envtools=y"
} >> .config

# 5. 备份并刷新时间戳，物理压制 mconf 交互
cp -fv .config .config.locked
find target/linux/mediatek/files-6.6/ -name "*.dts*" -exec touch {} + || true

echo "✅ SL3000 专用源码重构完成。"
