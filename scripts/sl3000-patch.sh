#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行全量延续修复 (原文照抄版)..."

cd "${WORKDIR}"

# [延续修复] 1. Feeds 稳定同步逻辑
for i in {1..3}; do
    ./scripts/feeds update -a && ./scripts/feeds install -a && break || sleep 5
done

# [延续修复] 2. 身份锁定
rm -rf tmp .config .config.old
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# [延续修复] 3. 三件套资产原封不动注入 (像素级守住你的 128MB 对齐 MK)
cat "${SRC_DIR}/sl3000.config" >> .config
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"

# [延续修复] 4. 工具链劫持 (原文照抄之前解决 bison/m4 的设置)
mkdir -p "staging_dir/host/bin"
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool"
done
touch "staging_dir/host/.tools_install_y"

# [延续修复] 5. 参数纠偏 (死守 512M RootFS)
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

echo "✅ [SL3000] 资产已全量归位，设置已完全延续。"
