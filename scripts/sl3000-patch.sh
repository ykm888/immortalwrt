#!/bin/bash
set -eo pipefail

# 物理死锁：获取脚本所在目录的上一级作为根目录，解决相对路径偏移
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}"

# 物理进入工作目录
cd "${WORKDIR}"

# 1. 体系延续：物理铲平冲突项 (原文照抄)
rm -rf package/boot/arm-trusted-firmware-microchipsw
rm -rf package/utils/audit
rm -rf package/emortal/autosamba
rm -rf package/utils/policycoreutils
rm -rf package/utils/pcat-manager

# 物理修复 24.10 依赖警告 (防止中断)
sed -i '/libaudit/d' package/libs/libsemanage/Makefile || true
sed -i '/audit\/host/d' package/libs/libsemanage/Makefile || true
sed -i '/policycoreutils\/host/d' package/system/refpolicy/Makefile || true
sed -i '/policycoreutils\/host/d' package/system/selinux-policy/Makefile || true

# 2. 全链路自愈：物理死锁配置 (原文照抄)
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_PACKAGE_u-boot-sl3000-emmc=y"
    echo "CONFIG_PACKAGE_atf-mt7981-sl3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1048576"
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

# 3. 全链路自愈：DTS 物理注入 (原文照抄)
DTS_PHY_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_PHY_DIR"
if [ -f "${SRC_DIR}/mt7981b-3000-emmc.dts" ]; then
    cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$DTS_PHY_DIR/mt7981b-3000-emmc.dts"
fi

# 核心自愈：补全 build_dir (防止编译中途被源码重置)
if [ -d "build_dir" ]; then
    find build_dir/ -type d -path "*/arch/arm64/boot/dts/mediatek" | while read -r dts_path; do
        cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$dts_path/"
    done
fi

# 4. 全链路自愈：Makefile 物理死锁 (原文照抄)
MK_TARGET="target/linux/mediatek/image/filogic.mk"
cat <<EOF > "filogic.mk.patch"

define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 (eMMC)
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := \$(LINUX_DIR)/arch/\$(ARCH)/boot/dts/mediatek
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
