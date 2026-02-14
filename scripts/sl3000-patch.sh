#!/bin/bash
set -eo pipefail

# 1. 物理定位：严格维持你从不更换的原始路径名称
REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
# 保持你一贯使用的源码配置目录名
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行 24.10 物理适配 (保持原始路径逻辑)...\033[0m"

# 2. 物理路径：锁定你一直设置的 files-6.6 路径
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
DTS_NAME="mt7981b-3000-emmc"

# 3. 物理注入动作 (严格原文顺序)
cd "$WORKDIR"
mkdir -p "$DTS_DEST"

echo "✅ 注入 DTS: ${DTS_DEST}/${DTS_NAME}.dts"
# 物理拷贝：直接从你从不更换的 SRC_DIR 提取文件
cp -fv "${SRC_DIR}/${DTS_NAME}.dts" "${DTS_DEST}/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 4. 配置固化：物理对齐 128MB+128MB 方案 (这是唯一需要物理锁定的错误修复)
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_3000-emmc=y"

    # 物理锁定内核与根文件系统分区 (KB)
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTNAME=\"rootfs\""

    echo "CONFIG_TARGET_ROOTFS_SQUASHFS=y"
    
    # 核心驱动与物理工具 (维持你之前的配置体系)
    echo "CONFIG_PACKAGE_kmod-mmc=y"
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_f2fs-tools=y"
    echo "CONFIG_PACKAGE_parted=y"
    echo "CONFIG_PACKAGE_lsblk=y"
    
    echo "CONFIG_PACKAGE_luci=y"
    echo "# CONFIG_SIGNED_PACKAGES is not set"
} > .config

# 5. 屏蔽签名逻辑
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true

echo -e "\033[32m✅ 路径与逻辑已物理闭环，准备编译。\033[0m"
