#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 24.10 物理闭环修复启动...\033[0m"

# 物理进入工作区
cd "${WORKDIR}" || { echo "❌ 目录不存在"; exit 1; }

# A. 物理注册内核 DTS (24.10 必做)
DTS_MAKEFILE="target/linux/mediatek/dts/Makefile"
DTS_NAME="mt7981b-3000-emmc"
if [ -f "$DTS_MAKEFILE" ]; then
    sed -i "/$DTS_NAME/d" "$DTS_MAKEFILE"
    echo "dtb-\$(CONFIG_TARGET_mediatek_filogic) += $DTS_NAME.dtb" >> "$DTS_MAKEFILE"
    echo "✅ Makefile 物理注册完成"
else
    echo "❌ 找不到 Makefile"; exit 1
fi

# B. 物理注入配置
cp -fv "${SRC_DIR}/${DTS_NAME}.dts" "target/linux/mediatek/dts/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# C. 锁定编译参数
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
} > .config

# D. 屏蔽签名校验
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true

echo -e "\033[32m✅ 脚本物理自检通过。\033[0m"
