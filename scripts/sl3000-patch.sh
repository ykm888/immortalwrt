#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行全量补丁归位：只加不减，物理焊死所有历史修复点..."

cd "${WORKDIR}"

# --- [修复点 1：2/9 屏蔽报错] ---
# 物理删除所有 Makefile 中的 -Werror 和 ERROR_ON_WARNING
find . -name Makefile -exec sed -i 's/ERROR_ON_WARNING = y/ERROR_ON_WARNING = n/g' {} +
find . -name "Makefile.dtc" -exec sed -i 's/-Werror//g' {} + || true
find . -name "Makefile*" -exec sed -i 's/-Werror//g' {} + || true

# --- [延续设置：Feeds 管理] ---
./scripts/feeds update -a && ./scripts/feeds install -a

# --- [修复点 2：2/5 Bison/M4 物理修复] ---
# 强行建立 host 映射，确保 flex/bison 始终调用宿主机最新工具
mkdir -p staging_dir/host/bin
mkdir -p staging_dir/host/share
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done
# 物理映射 m4sugar 数据目录 (关键：解决 bison 执行失败)
B_SHARE=$(pkg-config --variable=pkgdatadir bison 2>/dev/null || echo '/usr/share/bison')
ln -sf "$B_SHARE" "staging_dir/host/share/bison" || true

# --- [修复点 3：2/7 分区与内核锁定] ---
rm -f .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
    # 物理锁定变量环境
    echo "export BISON_PKGDATADIR=$B_SHARE"
    echo "export M4=$(which m4)"
} > .config
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# --- [修复点 4：2/7 DTS/Image 文件归位] ---
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# --- [修复点 5：2/7 Rootfs 1G 锁定] ---
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config
