#!/bin/bash
set -eo pipefail

# 1. 物理定位仓库根目录
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 24.10 物理路径精准对齐启动...\033[0m"

# 2. 物理强制进入 openwrt 目录
if [ -d "$WORKDIR" ]; then
    cd "$WORKDIR"
else
    echo -e "\033[31m❌ 致命错误: 找不到 openwrt 目录！\033[0m"
    exit 1
fi

# 3. 🔥 [物理路径对齐] 适配 24.10 内核 6.6 真实路径
# 根据你的 find 结果，这是 24.10 存放 DTS 的物理阵地
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
DTS_NAME="mt7981b-3000-emmc"

# 物理强制创建路径（以防 feeds 未完全拉取）
mkdir -p "$DTS_DEST"

# 4. 🔥 [物理注入文件]
echo "✅ 注入 DTS 至内核路径: $DTS_DEST"
cp -fv "${SRC_DIR}/${DTS_NAME}.dts" "${DTS_DEST}/"

# 注入 Image 配置文件
echo "✅ 注入 MK 至镜像构建路径"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 5. 🔥 [物理生成配置] 锁定 1024MB
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

# 6. 屏蔽签名
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true

echo -e "\033[32m✅ 24.10 物理路径对齐成功，DTS 已物理就位。\033[0m"
