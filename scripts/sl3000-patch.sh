#!/bin/bash
set -eo pipefail

# 1. 物理定位仓库根目录
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行 24.10 物理适配（不乱改版）...\033[0m"

# 2. 物理进入 openwrt 目录
if [ -d "$WORKDIR" ]; then
    cd "$WORKDIR"
else
    echo -e "\033[31m❌ 致命错误: 找不到 openwrt 目录！\033[0m"
    exit 1
fi

# 3. 🔥 [物理路径精准对齐] 适配 24.10 内核 6.6 
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
DTS_NAME="mt7981b-3000-emmc"

mkdir -p "$DTS_DEST"

# 4. 🔥 [物理注入]
echo "✅ 注入 DTS: ${DTS_DEST}/${DTS_NAME}.dts"
cp -fv "${SRC_DIR}/${DTS_NAME}.dts" "${DTS_DEST}/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 5. 🔥 [内核注册] 确保 24.10 内核识别新 DTS
KERNEL_MAKEFILE="${DTS_DEST}/Makefile"
if [ -f "$KERNEL_MAKEFILE" ]; then
    if ! grep -q "$DTS_NAME" "$KERNEL_MAKEFILE"; then
        echo "dtb-\$(CONFIG_ARCH_MEDIATEK) += ${DTS_NAME}.dtb" >> "$KERNEL_MAKEFILE"
        echo "✅ 已在内核 Makefile 注册 DTS"
    fi
fi

# 6. 🔥 [配置固化] 锁定 1024MB 分区
rm -f .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024"
    echo "CONFIG_TARGET_ROOTFS_PARTNAME=\"rootfs\""
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_f2fs-tools=y"
    echo "CONFIG_PACKAGE_gptfdisk=y"
    echo "CONFIG_PACKAGE_luci=y"
} > .config

# 7. 屏蔽签名
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true

echo -e "\033[32m✅ 24.10 物理路径对齐完成。\033[0m"
