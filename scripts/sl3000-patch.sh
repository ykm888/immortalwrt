#!/bin/bash
set -eo pipefail

# 1. 物理定位：严格遵循仓库原始路径名称
REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
# 物理修正：指向你真实的 custom-config 目录
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行 24.10 物理适配 + U-Boot 构建...\033[0m"

# 2. 物理路径：适配 24.10 内核 6.6
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
DTS_NAME="mt7981b-3000-emmc"

# 3. 物理注入
cd "$WORKDIR"
mkdir -p "$DTS_DEST"

echo "✅ 注入 DTS: ${DTS_DEST}/${DTS_NAME}.dts"
cp -fv "${SRC_DIR}/${DTS_NAME}.dts" "${DTS_DEST}/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 4. 配置固化：锁定 128MB 内核与 128MB Rootfs (总计 256MB)
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_3000-emmc=y"

    # 新增：构建匹配 SL3000 的 U-Boot 固件
    echo "CONFIG_PACKAGE_u-boot-mt7981-sl3000-emmc=y"

    # 物理锁定数值 (单位: KB)
    # 内核分区设为 128MB
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    # Rootfs 分区设为 128MB，确保固件总大小约 256MB
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTNAME=\"rootfs\""

    echo "CONFIG_TARGET_ROOTFS_SQUASHFS=y"
    echo "CONFIG_TARGET_IMAGES_GZIP=y"

    # 核心驱动 (24.10)
    echo "CONFIG_PACKAGE_kmod-mmc=y"
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_f2fs-tools=y"
    echo "CONFIG_PACKAGE_f2fsck=y"

    # 物理分区工具 (物理修复：添加 echo 指令)
    echo "CONFIG_PACKAGE_parted=y"
    echo "CONFIG_PACKAGE_lsblk=y"
    echo "CONFIG_PACKAGE_blkid=y"
    echo "CONFIG_PACKAGE_block-mount=y"

    # 系统增强
    echo "CONFIG_PACKAGE_kmod-zram=y"
    echo "CONFIG_PACKAGE_zram-swap=y"
    echo "CONFIG_PACKAGE_luci=y"
    echo "CONFIG_PACKAGE_luci-theme-bootstrap=y"
    echo "CONFIG_PACKAGE_curl=y"
    echo "CONFIG_PACKAGE_wget-ssl=y"
    echo "CONFIG_PACKAGE_htop=y"
    echo "CONFIG_PACKAGE_nano=y"

    # 物理屏蔽签名
    echo "# CONFIG_SIGNED_PACKAGES is not set"
} > .config

# 5. 屏蔽签名逻辑
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true

echo -e "\033[32m✅ 24.10 物理注入与 U-Boot 配置完成。\033[0m"
