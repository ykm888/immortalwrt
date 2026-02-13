#!/bin/bash
set -eo pipefail

# 物理路径锁定
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
# 自动探测工作目录：兼容 Actions 和本地路径
if [ -d "${REPO_ROOT}/openwrt" ]; then
    WORKDIR="${REPO_ROOT}/openwrt"
else
    WORKDIR="${REPO_ROOT}"
fi
SRC_DIR="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

echo -e "\033[32m🚀 [SL3000] 执行 24.10 物理适配...\033[0m"

# 1. 🔥 [物理路径预检] 
# 如果 Makefile 不存在，说明 feeds 还没准备好，强制报错停止，防止生成“残废”固件
DTS_MAKEFILE="target/linux/mediatek/dts/Makefile"
if [ ! -f "$DTS_MAKEFILE" ]; then
    echo -e "\033[31m❌ 错误: 找不到 $DTS_MAKEFILE，请确保脚本在 openwrt 根目录运行且 feeds 已安装。\033[0m"
    exit 1
fi

# 2. 🔥 [物理清算] 
rm -rf bin/targets/mediatek/filogic/*
# 忽略初次编译时 build_dir 不存在的报错
find build_dir/ -name "*sl3000*" -exec rm -rf {} + 2>/dev/null || true

# 3. 🔥 [物理注入并注册 DTS] 
TARGET_DTS="mt7981b-3000-emmc.dts"
DTS_DEST="target/linux/mediatek/dts"

if [ -f "${SRC_DIR}/${TARGET_DTS}" ]; then
    cp -fv "${SRC_DIR}/${TARGET_DTS}" "$DTS_DEST/"
    DTS_NAME="${TARGET_DTS%.*}"
    # 物理去重注册：确保 Makefile 里只有一行
    sed -i "/$DTS_NAME/d" "$DTS_MAKEFILE"
    echo "dtb-\$(CONFIG_TARGET_mediatek_filogic) += $DTS_NAME.dtb" >> "$DTS_MAKEFILE"
    echo "✅ DTS 物理注册成功: $DTS_NAME"
fi

# 4. 🔥 [物理配置锁定] 
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

# 5. 🔥 [物理覆盖 MK]
if [ -f "${SRC_DIR}/filogic.mk" ]; then
    cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/filogic.mk
    touch target/linux/mediatek/image/filogic.mk
fi

echo -e "\033[32m✅ 24.10 物理补丁注入完成。\033[0m"
