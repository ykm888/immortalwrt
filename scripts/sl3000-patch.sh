#!/bin/bash
set -eo pipefail

REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行终极物理死锁适配 (128MB 强制对齐)...\033[0m"

# 1. 物理注入资源 (DTS 与 Image 定义)
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$WORKDIR/$DTS_DEST"
cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$WORKDIR/$DTS_DEST/"
cp -fv "${SRC_DIR}/filogic.mk" "$WORKDIR/target/linux/mediatek/image/filogic.mk"

cd "$WORKDIR"

# 2. 物理锁定：强制构建核心配置块
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_3000-emmc=y"
    
    # U-Boot & FIP 产出死锁 (确保产生 fip.bin)
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    echo "CONFIG_PACKAGE_mtk-bmt-mtd=y"
    echo "CONFIG_TARGET_IMAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    
    # 物理偏移锁定 (128MB = 131072 KB)
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTNAME=\"rootfs\""
    
    # 物理驱动与核心包
    echo "CONFIG_PACKAGE_kmod-mmc=y"
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_f2fs-tools=y"
    echo "CONFIG_PACKAGE_luci=y"
    echo "CONFIG_PACKAGE_luci-theme-bootstrap=y"
    echo "# CONFIG_SIGNED_PACKAGES is not set"
} > .config

# 3. 物理防御：通过 sed 强制修正任何可能的系统回滚项
sed -i 's/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=131072/' .config
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=131072/' .config

# 4. 生成强灌源
cp -fv .config .config.locked
echo "✅ 物理补丁已生成并锁定。"
