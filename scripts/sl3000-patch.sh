#!/bin/bash
set -eo pipefail

# 1. 物理定位仓库根目录
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 物理闭环修复启动...\033[0m"
echo "当前运行位置: $(pwd)"
echo "预设工作目录: ${WORKDIR}"

# 2. 物理强制进入 openwrt 目录
if [ -d "$WORKDIR" ]; then
    cd "$WORKDIR"
    echo "✅ 已进入目录: $(pwd)"
else
    echo -e "\033[31m❌ 致命错误: 找不到 openwrt 目录！\033[0m"
    ls -lh "${REPO_ROOT}"
    exit 1
fi

# 3. 物理 Makefile 注册 (针对 24.10 路径)
DTS_MAKEFILE="target/linux/mediatek/dts/Makefile"
DTS_NAME="mt7981b-3000-emmc"

if [ -f "$DTS_MAKEFILE" ]; then
    # 强制清理旧记录并追加
    sed -i "/$DTS_NAME/d" "$DTS_MAKEFILE"
    echo "dtb-\$(CONFIG_TARGET_mediatek_filogic) += $DTS_NAME.dtb" >> "$DTS_MAKEFILE"
    echo "✅ Makefile 内核编译链物理注册完成"
else
    echo -e "\033[31m❌ 致命错误: 物理路径失效，找不到 $DTS_MAKEFILE\033[0m"
    # 尝试列出目录辅助诊断
    find target/linux/mediatek -name "Makefile" || true
    exit 1
fi

# 4. 物理注入 DTS 和 MK
echo "注入 DTS: ${SRC_DIR}/${DTS_NAME}.dts"
cp -fv "${SRC_DIR}/${DTS_NAME}.dts" "target/linux/mediatek/dts/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 5. 物理锁定 1024MB 配置
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

# 6. 屏蔽签名
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true

echo -e "\033[32m✅ 24.10 物理补丁注入成功！\033[0m"
