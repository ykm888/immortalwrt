#!/bin/bash
# SL3000 物理指纹同步与源码重构脚本 (Final Version)
set -eo pipefail

REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 开始物理重构 SL3000 专用源码 (适配 Kernel 6.6)...\033[0m"

# 1. 物理注入核心组件
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$WORKDIR/$DTS_DEST"

# 物理同步：注入你的核心 DTS 和镜像生成规则
cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$WORKDIR/$DTS_DEST/"
cp -fv "${SRC_DIR}/filogic.mk" "$WORKDIR/target/linux/mediatek/image/filogic.mk"

cd "$WORKDIR"

# 2. 【关键修复】：物理修正 DTS 引用路径以适配 24.10
# 24.10 使用内核标准引用方式，必须修改，否则编译会报错找不到 mt7981.dtsi
DTS_FILE="$DTS_DEST/mt7981b-3000-emmc.dts"
if [ -f "$DTS_FILE" ]; then
    sed -i 's|#include "mt7981.dtsi"|#include <arm64/mediatek/mt7981.dtsi>|g' "$DTS_FILE"
    # 物理身份同步：确保与 23.05 的 U-Boot 识别号一致
    sed -i 's/compatible = .*/compatible = "sl,3000-emmc", "mediatek,mt7981";/' "$DTS_FILE"
    sed -i 's/model = .*/model = "SL-3000 eMMC bootstrap version";/' "$DTS_FILE"
fi

# 3. 物理名称对齐：强制 Makefile 使用 3000-emmc ID
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/sl3000/3000-emmc/g' {} + || true

# 4. 物理锁定：128MB 分区、U-Boot 生成与 eMMC 驱动
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_3000-emmc=y"
    # 强制编译 U-Boot (FIP)
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    echo "CONFIG_TARGET_IMAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    # 物理锁定 128MB 偏移 (131072 KB)
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=131072"
    # 物理锁定 eMMC 必要驱动
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y"
    echo "CONFIG_PACKAGE_kmod-gpt=y"
} >> .config

# 5. 备份并刷新时间戳，防止 mconf 扫描死循环
cp -fv .config .config.locked
find target/linux/mediatek/files-6.6/ -name "*.dts*" -exec touch {} + || true

echo "✅ SL3000 专用源码重构完成。"
