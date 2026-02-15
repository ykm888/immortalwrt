#!/bin/bash
set -eo pipefail

# 严格承袭：原始路径变量结构
REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行物理适配 (全量补丁注入)...\033[0m"

# 1. 资源物理注入 (原文照抄逻辑)
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$WORKDIR/$DTS_DEST"
cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$WORKDIR/$DTS_DEST/"
cp -fv "${SRC_DIR}/filogic.mk" "$WORKDIR/target/linux/mediatek/image/filogic.mk"

cd "$WORKDIR"

# 2. 物理修复：一次性锁定 128MB 偏移并强制产出 U-Boot
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_3000-emmc=y"
    # 物理锁定：确保 U-Boot 被选中（解决不生成 u-boot 的问题）
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    echo "CONFIG_TARGET_IMAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    # 物理锁定：修复 128MB 分区偏移报错
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTNAME=\"rootfs\""
    # 物理锁定：补全 eMMC 识别驱动与分区工具
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y"
    echo "CONFIG_PACKAGE_kmod-gpt=y"
    echo "CONFIG_PACKAGE_kmod-part-msdos=y"
    echo "CONFIG_PACKAGE_luci=y"
} >> .config

# 生成物理锁定的备份配置，用于工作流的二次强灌
cp -fv .config .config.locked
echo "✅ 补丁脚本执行完毕，已全量锁定配置。"
