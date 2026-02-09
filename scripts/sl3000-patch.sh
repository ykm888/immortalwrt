#!/bin/bash
set -e
# 原文照抄，只改错误，严禁画蛇添足
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行全量补丁物理归位..."
cd "${WORKDIR}"

# [1] 物理屏蔽 Werror (2/9 补丁)
find . -name Makefile -exec sed -i 's/ERROR_ON_WARNING = y/ERROR_ON_WARNING = n/g' {} +
find . -name "Makefile.dtc" -exec sed -i 's/-Werror//g' {} + || true

# [2] 更新 Feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# [3] Bison/M4 物理修复 (2/5 补丁)
mkdir -p staging_dir/host/bin
mkdir -p staging_dir/host/share
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done
B_SHARE=$(pkg-config --variable=pkgdatadir bison 2>/dev/null || echo '/usr/share/bison')
ln -sf "$B_SHARE" "staging_dir/host/share/bison" || true

# [4] 锁定内核分区与配置 (2/7 补丁)
rm -f .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
    echo "export BISON_PKGDATADIR=$B_SHARE"
    echo "export M4=$(which m4)"
} > .config
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# [5] DTS 注入与 1G 分区锁定 (2/7 补丁)
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config
