#!/bin/bash
set -eo pipefail

# 1. 物理定位：严格遵循仓库原始路径名称
REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
# 物理修正：指向你真实的 custom-config 目录
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行 24.10 物理适配（路径对齐版）...\033[0m"

# 2. 物理路径：适配 24.10 内核 6.6
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
DTS_NAME="mt7981b-3000-emmc"

# 3. 物理注入
cd "$WORKDIR"
mkdir -p "$DTS_DEST"

echo "✅ 注入 DTS: ${DTS_DEST}/${DTS_NAME}.dts"
cp -fv "${SRC_DIR}/${DTS_NAME}.dts" "${DTS_DEST}/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 4. 配置固化：使用覆盖模式，物理对齐 128MB (131072 KB) 偏移
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_3000-emmc=y"
    # 物理锁定：128MB = 131072 KB
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    # 物理锁定：1024MB = 1048576 KB
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1048576"
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
