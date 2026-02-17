#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}"

cd "${WORKDIR}"

# 1. 【体系延续】物理铲平冲突项 (原文照抄，严禁漏掉之前任何补丁)
rm -rf package/boot/arm-trusted-firmware-microchipsw
rm -rf package/utils/audit
rm -rf package/emortal/autosamba
rm -rf package/utils/policycoreutils
rm -rf package/utils/pcat-manager

# 2. 【体系延续】物理死锁配置 (单位锁死，激活引导件)
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_PACKAGE_u-boot-sl3000-emmc=y"
    echo "CONFIG_PACKAGE_atf-mt7981-sl3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1048576"
    # 延续所有核心插件
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
} > .config.locked

# 3. 🔥【路径放宽】全自动物理修复 (修复报错的同时不破坏原有体系)
# 注入静态源码路径
mkdir -p "target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
[ -f "${SRC_DIR}/mt7981b-3000-emmc.dts" ] && cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/"

# 注入动态构建路径 (暴力搜索所有潜在的内核架构目录)
if [ -d "build_dir" ]; then
    find build_dir/ -type d -path "*/arch/arm64/boot/dts/mediatek" | while read -r dts_path; do
        cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$dts_path/"
        # 建立 aarch64 到 arm64 的物理映射兼容层
        arch_base=$(echo "$dts_path" | sed 's|/arm64/boot/dts/mediatek||')
        if [ -d "$arch_base/arm64" ] && [ ! -e "$arch_base/aarch64" ]; then
            ln -sf arm64 "$arch_base/aarch64"
        fi
    done
fi

# 4. 【体系延续】Makefile 物理加固
MK_TARGET="target/linux/mediatek/image/filogic.mk"
cat <<EOF > "filogic.mk.patch"

define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 (eMMC)
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := \$(LINUX_DIR)/arch/arm64/boot/dts/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc mediatek,mt7981
  BOARD_ROOTFS_PARTSIZE := 1024
  DEVICE_PACKAGES := kmod-mmc kmod-sdhci-mtk kmod-fs-f2fs f2fs-tools f2fsck \\
	parted lsblk blkid block-mount kmod-zram zram-swap \\
	u-boot-sl3000-emmc atf-mt7981-sl3000-emmc
  KERNEL := kernel-bin | lzma | uImage lzma
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
EOF
cat "filogic.mk.patch" >> "$MK_TARGET"
