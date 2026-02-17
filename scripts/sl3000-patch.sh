#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}"

cd "${WORKDIR}"

# 1. 体系延续：物理铲平冲突项 (原文照抄，严禁漏掉任何之前验证过的补丁)
rm -rf package/boot/arm-trusted-firmware-microchipsw
rm -rf package/utils/audit
rm -rf package/emortal/autosamba
rm -rf package/utils/policycoreutils
rm -rf package/utils/pcat-manager

# 2. 全链路自愈：物理死锁配置 (单位锁死 131072KB + 激活引导构建)
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    
    # 物理激活 U-Boot 与 ATF (FIP)
    echo "CONFIG_PACKAGE_u-boot-sl3000-emmc=y"
    echo "CONFIG_PACKAGE_atf-mt7981-sl3000-emmc=y"
    
    # 物理死锁单位：128MB=131072, 1024MB=1048576 (杜绝 24.10 审计报错)
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1048576"
    
    # 物理延续：核心插件体系
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

# 3. 全链路自愈：DTS 物理注入 (files-6.6 架构死锁)
DTS_PHY_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_PHY_DIR"
if [ -f "${SRC_DIR}/mt7981b-3000-emmc.dts" ]; then
    cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$DTS_PHY_DIR/mt7981b-3000-emmc.dts"
fi

# 4. 全链路自愈：Makefile 物理死锁 (纠偏 24.10 打包宏)
MK_TARGET="target/linux/mediatek/image/filogic.mk"
cat <<EOF > "filogic.mk.patch"

define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 (eMMC)
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := \$(LINUX_DIR)/arch/\$(ARCH)/boot/dts/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc mediatek,mt7981
  BOARD_ROOTFS_PARTSIZE := 1024
  # 物理强灌包依赖，强制触发 U-Boot 构建
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
