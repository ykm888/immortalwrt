#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行物理清算：锁定 3000-emmc 并强制重编...\033[0m"

cd "${WORKDIR}"

# 1. 🔥 [物理清算] 解决“3秒生成”的真凶
# 物理删除所有带 sl3000 标识的中间文件，强制触发重新搜索 DTS 和 MK
find build_dir/ -name "*sl3000*" -exec rm -rf {} + || true
find build_dir/ -name ".image_done" -delete || true
rm -rf bin/targets/mediatek/filogic/*

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

# 3. 🔥 [物理注入 DTS] 注入 mt7981b-3000-emmc.dts
TARGET_DTS="mt7981b-3000-emmc.dts"
KERNEL_DTS_DIRS=$(find target/linux/mediatek/ build_dir/target-* -type d -path "*/arch/arm64/boot/dts/mediatek" 2>/dev/null || true)

if [ -f "${SRC_DIR}/${TARGET_DTS}" ]; then
    for dts_dir in $KERNEL_DTS_DIRS; do
        cp -fv "${SRC_DIR}/${TARGET_DTS}" "$dts_dir/"
        sed -i 's/sl,sl3000-emmc/sl,3000-emmc/g' "$dts_dir/${TARGET_DTS}"
    done
fi

# 4. 🔥 [物理镜像 MK 修正] 
mkdir -p target/linux/mediatek/image
if [ -f "${SRC_DIR}/filogic.mk" ]; then
    cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/
    # 强制修正 MK 内部的设备定义名为 3000-emmc
    sed -i "s/Device\/sl3000-emmc/Device\/3000-emmc/g" target/linux/mediatek/image/filogic.mk
    sed -i "s/TARGET_DEVICES += sl3000-emmc/TARGET_DEVICES += 3000-emmc/g" target/linux/mediatek/image/filogic.mk
    sed -i 's/pad-to/append-string/g' target/linux/mediatek/image/filogic.mk || true
fi

# 5. 屏蔽签名校验
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

echo -e "\033[32m✅ 物理补丁注入完成，旧缓存标记已清空。\033[0m"
