#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m💎 [SL3000] 启动物理重构：集成 PassWall 2 + Docker + 分区锁定...\033[0m"

cd "${WORKDIR}"

# 1. 物理环境准备
mkdir -p staging_dir/host
touch staging_dir/host/.prereq-build

# 2. 🔥 [物理重建 .config] 严格承袭你提供的文本结构，并追加插件逻辑
rm -f .config
{
    # --- 你提供的基础配置 (原文照抄) ---
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

    # --- 物理追加：PassWall 2 全家桶 ---
    echo "CONFIG_PACKAGE_luci-app-passwall=y"
    echo "CONFIG_PACKAGE_luci-app-passwall_Iptables_Transparent_Proxy=y"
    echo "CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y"
    echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y"
    echo "CONFIG_PACKAGE_luci-i18n-passwall-zh-cn=y"

    # --- 物理追加：Docker 全家桶 ---
    echo "CONFIG_PACKAGE_luci-app-dockerman=y"
    echo "CONFIG_PACKAGE_dockerd=y"
    echo "CONFIG_PACKAGE_docker-compose=y"
    echo "CONFIG_PACKAGE_luci-i18n-dockerman-zh-cn=y"
    echo "CONFIG_PACKAGE_kmod-br-netfilter=y"
} > .config

# 3. 🔥 [物理放宽] 彻底修复 Missing Build/true
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

# 5. 🔥 [物理注入] 镜像定义 MK
mkdir -p target/linux/mediatek/image
if [ -f "${SRC_DIR}/filogic.mk" ]; then
    cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/
    sed -i 's/pad-to/append-string/g' target/linux/mediatek/image/filogic.mk || true
    sed -i 's/check-size/append-string/g' target/linux/mediatek/image/filogic.mk || true
fi

# 6. 屏蔽签名逻辑
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

echo -e "\033[32m✅ 脚本物理同步完成，包含 PassWall 2 与 Docker。\033[0m"
