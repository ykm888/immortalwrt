#!/bin/bash
set -eo pipefail

# 物理路径自寻优
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行 24.10 物理适配：延续原有工程体系...\033[0m"

# 物理对齐工作目录
if [ -d "$WORKDIR" ]; then
    cd "$WORKDIR"
else
    echo "❌ 找不到 openwrt 目录"; exit 1
fi

# 1. 🔥 [物理清算]
rm -rf bin/targets/mediatek/filogic/*
find build_dir/ -name "*sl3000*" -exec rm -rf {} + 2>/dev/null || true

# 2. 🔥 [物理 Makefile 注册] - 24.10 核心修复
DTS_MAKEFILE="target/linux/mediatek/dts/Makefile"
DTS_NAME="mt7981b-3000-emmc"
if [ -f "$DTS_MAKEFILE" ]; then
    sed -i "/$DTS_NAME/d" "$DTS_MAKEFILE"
    echo "dtb-\$(CONFIG_TARGET_mediatek_filogic) += $DTS_NAME.dtb" >> "$DTS_MAKEFILE"
    echo "✅ 内核编译链注册成功"
else
    echo "❌ 致命错误: 找不到 $DTS_MAKEFILE"; exit 1
fi

# 3. 🔥 [物理注入 DTS & MK]
cp -fv "${SRC_DIR}/${DTS_NAME}.dts" "target/linux/mediatek/dts/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 4. 🔥 [物理生成配置]
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

# 5. 🔥 [物理屏蔽签名]
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true

echo -e "\033[32m✅ 24.10 物理补丁注入完成。\033[0m"
