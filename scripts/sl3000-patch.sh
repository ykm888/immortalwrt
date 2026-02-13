#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行 24.10 物理适配：锁定 3000-emmc 并强制重编...\033[0m"

cd "${WORKDIR}"

# 1. 🔥 [物理清算] 彻底清除 24.10 的 ImageBuilder 缓存元数据
# 24.10 的元数据存储在 json 和 tmp 目录，必须物理抹除以防识别旧指纹
rm -rf bin/targets/mediatek/filogic/*
rm -rf tmp/.config-target.in
find build_dir/target-* -name "*.json" -delete || true
find build_dir/target-* -name ".image_done" -delete || true
# 清理旧 ID 遗迹
find build_dir/ -name "*sl3000*" -exec rm -rf {} + || true

# 2. 🔥 [物理重建 .config] 
rm -f .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024"
    echo "CONFIG_TARGET_ROOTFS_SQUASHFS=y"
    echo "CONFIG_TARGET_IMAGES_GZIP=y"
    echo "CONFIG_PACKAGE_kmod-mmc=y"
    echo "CONFIG_PACKAGE_kmod-sdhci-mtk=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_f2fs-tools=y"
    echo "CONFIG_PACKAGE_f2fsck=y"
    echo "CONFIG_PACKAGE_parted=y"
    echo "CONFIG_PACKAGE_lsblk=y"
    echo "CONFIG_PACKAGE_blkid=y"
    echo "CONFIG_PACKAGE_block-mount=y"
    echo "CONFIG_PACKAGE_kmod-zram=y"
    echo "CONFIG_PACKAGE_zram-swap=y"
    echo "CONFIG_PACKAGE_luci=y"
    echo "CONFIG_PACKAGE_luci-theme-bootstrap=y"
    echo "CONFIG_PACKAGE_curl=y"
    echo "CONFIG_PACKAGE_wget-ssl=y"
    echo "CONFIG_PACKAGE_htop=y"
    echo "CONFIG_PACKAGE_nano=y"
} > .config

# 3. 🔥 [物理注入 DTS] 适配 24.10 内核 6.6 编译链
TARGET_DTS="mt7981b-3000-emmc.dts"
# 物理路径：24.10 的 DTS 位于 target/linux/mediatek/dts/
DTS_DEST="target/linux/mediatek/dts"
mkdir -p "$DTS_DEST"

if [ -f "${SRC_DIR}/${TARGET_DTS}" ]; then
    echo "Injecting DTS: ${TARGET_DTS}"
    cp -fv "${SRC_DIR}/${TARGET_DTS}" "$DTS_DEST/"
    
    # 🔥 24.10 核心修复：必须将自定义 DTS 注册进 target 的 Makefile 才能生成 .dtb
    DTS_MAKEFILE="target/linux/mediatek/dts/Makefile"
    DTS_NAME="${TARGET_DTS%.*}"
    if ! grep -q "$DTS_NAME" "$DTS_MAKEFILE"; then
        echo "Registering $DTS_NAME to $DTS_MAKEFILE"
        echo "dtb-\$(CONFIG_TARGET_mediatek_filogic) += $DTS_NAME.dtb" >> "$DTS_MAKEFILE"
    fi
fi

# 4. 🔥 [物理镜像 MK 修正] 
if [ -f "${SRC_DIR}/filogic.mk" ]; then
    echo "Injecting MK: filogic.mk"
    mkdir -p target/linux/mediatek/image
    cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/filogic.mk
    # 强制更新 Makefile 时间戳以触发解析
    touch target/linux/mediatek/image/filogic.mk
fi

# 5. 屏蔽签名校验
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

echo -e "\033[32m✅ 24.10 物理补丁注入完成，DTS 已注册。即将开始真正的重编流程。\033[0m"
