#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行全量延续修复 (资产锁定版)..."

cd "${WORKDIR}"

# [延续] 1. Feeds 同步
for i in {1..3}; do
    ./scripts/feeds update -a && ./scripts/feeds install -a && break || sleep 5
done

# [延续] 2. 身份锁定
rm -rf tmp .config .config.old
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# [延续] 3. 三件套资产原封不动注入 (死守你修好的 128MB 对齐逻辑)
cat "${SRC_DIR}/sl3000.config" >> .config
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"

# [延续] 4. 工具链环境劫持 (针对 Error 127 的物理锁定)
mkdir -p "staging_dir/host/bin"
# 🎯 物理占位：确保系统根路径预留位置
sudo ln -sf "$(pwd)/staging_dir/host/bin/fwtool" /usr/bin/fwtool || true
sudo ln -sf "$(pwd)/staging_dir/host/bin/opkg" /usr/bin/opkg || true

for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool"
done
touch "staging_dir/host/.tools_install_y"

# [延续] 5. 512MB 空间限制
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

echo "✅ [SL3000] 所有之前修复的设置已全量延续。"
