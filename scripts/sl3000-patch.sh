#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}"

cd "${WORKDIR}"

# 1. 物理铲平导致扫描失败的源头 (保留上一版逻辑)
rm -rf package/boot/arm-trusted-firmware-microchipsw
rm -rf package/utils/audit
rm -rf package/emortal/autosamba
rm -rf package/utils/policycoreutils
rm -rf package/utils/pcat-manager

# 2. 🔥 [.config.locked] 物理换算与逻辑死锁
# 核心修正：128MB -> 131072KB, 1024MB -> 1048576KB
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_PACKAGE_u-boot-sl3000-emmc=y"
    echo "CONFIG_PACKAGE_atf-mt7981-sl3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1048576"
    
    # 物理延续原始插件清单
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
} > .config.locked

# 3. 🔥 [DTS/MK 注入] 物理对齐 24.10 (Kernel 6.6)
# 修正路径：从 files-6.1 改为 files-6.6
DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_DIR"

if [ -f "${SRC_DIR}/mt7981b-3000-emmc.dts" ]; then
    cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$DTS_DIR/mt7981b-3000-emmc.dts"
    echo "✅ DTS 物理注入完成: $DTS_DIR"
fi

# 4. 🔥 [Makefile 修正] 物理锁定设备定义
MK_TARGET="target/linux/mediatek/image/filogic.mk"
cat <<EOF > "filogic.mk.patch"
define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 (eMMC)
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := \$(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc mediatek,mt7981
  BOARD_ROOTFS_PARTSIZE := 1024
  DEVICE_PACKAGES := kmod-mmc kmod-sdhci-mtk kmod-fs-f2fs f2fs-tools f2fsck \\
	parted lsblk blkid block-mount kmod-zram zram-swap
  KERNEL := kernel-bin | lzma | uImage lzma
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
EOF

# 物理追加而非覆盖，防止破坏 Makefile 结构
cat "filogic.mk.patch" >> "$MK_TARGET"

echo "🚀 脚本修复完成：单位已换算，路径已对齐至 Kernel 6.6。"
