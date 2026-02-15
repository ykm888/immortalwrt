#!/bin/bash
set -eo pipefail

REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行 24.10 物理适配 (U-Boot 强制对齐版)...\033[0m"

DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
DTS_NAME="mt7981b-3000-emmc"

cd "$WORKDIR"
mkdir -p "$DTS_DEST"

echo "✅ 注入 DTS: ${DTS_DEST}/${DTS_NAME}.dts"
cp -fv "${SRC_DIR}/${DTS_NAME}.dts" "${DTS_DEST}/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_3000-emmc=y"
    
    # --- 物理死锁补足：确保产出 U-Boot 和 FIP ---
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    echo "CONFIG_PACKAGE_mtk-bmt-mtd=y"
    echo "CONFIG_TARGET_IMAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    # ------------------------------------------

    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTNAME=\"rootfs\""
    echo "CONFIG_TARGET_ROOTFS_SQUASHFS=y"
    
    echo "CONFIG_PACKAGE_kmod-mmc=y"
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_f2fs-tools=y"
    echo "CONFIG_PACKAGE_parted=y"
    echo "CONFIG_PACKAGE_lsblk=y"
    echo "CONFIG_PACKAGE_luci=y"
    echo "# CONFIG_SIGNED_PACKAGES is not set"
} > .config

sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true

echo -e "\033[32m✅ 物理死锁已完成，U-Boot 与 128MB 偏移已就绪。\033[0m"
