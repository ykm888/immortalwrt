#!/bin/bash
set -eo pipefail

REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行 24.10 物理适配...\033[0m"

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

echo -e "\033[32m✅ 路径与逻辑已物理闭环，准备编译。\033[0m"
