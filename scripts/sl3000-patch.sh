#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 深度修复与资产注入 (严谨版)..."

# 0. 前置检查：防止文件丢失导致后续徒劳运行
if [ ! -d "$SRC_DIR" ]; then
    echo "❌ 错误: 找不到 custom-config 目录！"
    exit 1
fi

cd "${WORKDIR}"

# 1. Feeds 处理
./scripts/feeds update -a && ./scripts/feeds install -a

# 2. 身份与内核版本锁定
rm -rf tmp .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_LINUX_6_6=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
} > .config

# 3. 核心资产物理注入 (先删再拷，DTS 唯一化)
cat "${SRC_DIR}/sl3000.config" >> .config

mkdir -p "target/linux/mediatek/image"
rm -f "target/linux/mediatek/image/filogic.mk"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

mkdir -p "target/linux/mediatek/dts"
rm -f "target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"

# 4. 目录预热
mkdir -p "staging_dir/host/bin"

# 5. 分区锁定
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

echo "✅ [SL3000] 资产注入完成。"
