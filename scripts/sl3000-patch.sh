#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行全量延续修复 (修正版)..."

cd "${WORKDIR}"

# [延续原文] 1. Feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# [延续原文] 2. 身份锁定
rm -rf tmp .config
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# [延续原文] 3. 三件套资产注入 (128MB对齐/1GB内存/512M分区)
cat "${SRC_DIR}/sl3000.config" >> .config
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"

# [🎯 错误修复] 4. 工具链物理加固
# 不再用 sed 修改 Makefile 源码（防止引起语法错），改为直接劫持系统路径
mkdir -p "staging_dir/host/bin"
sudo ln -sf "$(pwd)/staging_dir/host/bin/fwtool" /usr/bin/fwtool || true
sudo ln -sf "$(pwd)/staging_dir/host/bin/opkg" /usr/bin/opkg || true

# [延续原文] 5. 环境补丁
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

echo "✅ [SL3000] 补丁注入完成，所有历史修复已锁定。"
