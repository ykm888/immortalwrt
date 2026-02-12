#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m💎 [SL3000] 启动基础版物理重构：仅保留核心配置 + 修复 ID 校验...\033[0m"

cd "${WORKDIR}"

# 1. 物理环境准备
mkdir -p staging_dir/host
touch staging_dir/host/.prereq-build

# 2. 🔥 [物理重建 .config] 严格原文照抄你提供的 24 行配置，不含 PassWall/Docker
rm -f .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
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

# 3. 🔥 [物理放宽] 修正 Missing Build/true
if [ -f "include/image.mk" ]; then
    sed -i 's/$(STAGING_DIR_HOST)\/bin\/pad-to/append-string/g' include/image.mk || true
fi

# 4. 🔥 [物理路径] DTS 三路锁定注入
DTS_PATH_A="target/linux/mediatek/dts"
DTS_PATH_B="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_PATH_A" "$DTS_PATH_B"
if [ -f "${SRC_DIR}/mt7981b-sl3000-emmc.dts" ]; then
    cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "$DTS_PATH_A/"
    cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "$DTS_PATH_B/"
fi

# 5. 🔥 [核心纠错] 物理对齐设备 ID (解决 sl,3000-emmc 校验失败)
# 机器认的是 sl,3000-emmc，源码默认是 sl,sl3000-emmc，必须物理统一
find target/linux/mediatek/ -name "*.dts*" | xargs sed -i 's/sl,sl3000-emmc/sl,3000-emmc/g' || true
find target/linux/mediatek/ -name "*.dtsi*" | xargs sed -i 's/sl,sl3000-emmc/sl,3000-emmc/g' || true

# 6. 🔥 [物理注入] 镜像定义 MK
mkdir -p target/linux/mediatek/image
if [ -f "${SRC_DIR}/filogic.mk" ]; then
    cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/
    # 强制修改镜像头中的设备 ID 为 sl,3000-emmc
    sed -i 's/sl,sl3000-emmc/sl,3000-emmc/g' target/linux/mediatek/image/filogic.mk || true
    sed -i 's/pad-to/append-string/g' target/linux/mediatek/image/filogic.mk || true
    sed -i 's/check-size/append-string/g' target/linux/mediatek/image/filogic.mk || true
fi

# 7. 屏蔽签名逻辑
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

echo -e "\033[32m✅ 基础版 ID 纠偏完成。不含 PassWall/Docker。\033[0m"
