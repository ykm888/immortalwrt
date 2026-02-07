#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 历史修复全量延续 (锁定版)..."

cd "${WORKDIR}"

# 1. [延续修复] Feeds 同步
./scripts/feeds update -a && ./scripts/feeds install -a

# 2. [延续修复] 身份配置锁定
rm -rf tmp .config
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# 3. [核心资产延续] 128MB对齐/1GB内存/DTS 物理注入 (严禁空格)
cat "${SRC_DIR}/sl3000.config" >> .config
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"

# 4. [工具链加固] 物理锁定 fwtool 解决 Error 127
mkdir -p "staging_dir/host/bin"
sudo ln -sf "$(pwd)/staging_dir/host/bin/fwtool" /usr/bin/fwtool || true
sudo ln -sf "$(pwd)/staging_dir/host/bin/opkg" /usr/bin/opkg || true

# 5. [环境延续修复] Bison/M4 补丁 (原文像素级还原)
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done

# 6. [溢出修复延续] 512MB 分区锁定
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

echo "✅ [SL3000] 资产锁定完成。"
