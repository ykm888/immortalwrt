#!/bin/bash
set -eo pipefail

# 1. 物理定位：使用 GitHub Actions 标准变量
WORKDIR="${GITHUB_WORKSPACE}/openwrt"
SRC_DIR="${GITHUB_WORKSPACE}"

echo -e "\033[32m🚀 [SL3000] 执行 24.10 物理路径对齐（纯净版）...\033[0m"

# 2. 物理路径：适配 24.10 内核 6.6
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
DTS_NAME="mt7981b-3000-emmc"

cd "$WORKDIR"
mkdir -p "$DTS_DEST"

# 3. 物理注入：直接从根目录拷贝（不经过 custom-config）
cp -fv "${SRC_DIR}/${DTS_NAME}.dts" "${DTS_DEST}/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 4. 配置固化：使用 > 覆盖模式，确保物理参数唯一性
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024"
    echo "CONFIG_TARGET_ROOTFS_PARTNAME=\"rootfs\""
    echo "CONFIG_PACKAGE_kmod-mmc=y"
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_f2fs-tools=y"
    echo "CONFIG_PACKAGE_f2fsck=y"
    echo "CONFIG_PACKAGE_luci=y"
} > .config

# 5. 屏蔽签名
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true

echo -e "\033[32m✅ 24.10 物理注入完成。\033[0m"
