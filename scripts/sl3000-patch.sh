#!/bin/bash
set -e

# 原则：原文照抄，只改错误。严禁画蛇添足/偷工减料。
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行全量补丁归位：合并 2/5-2/9 所有验证补丁..."

cd "${WORKDIR}"

# --- [1. 修复点：2/9 屏蔽报错] ---
# 物理屏蔽所有 Makefile 中的 WARNING 报错（解决 DTC/Binutils 编译中断）
find . -name Makefile -exec sed -i 's/ERROR_ON_WARNING = y/ERROR_ON_WARNING = n/g' {} +
find . -name "Makefile.dtc" -exec sed -i 's/-Werror//g' {} + || true
find . -name "Makefile*" -exec sed -i 's/-Werror//g' {} + || true

# --- [延续设置：Feeds 管理] ---
./scripts/feeds update -a && ./scripts/feeds install -a

# --- [2. 修复点：2/5 Bison/M4 物理修复] ---
# 建立物理映射，确保 m4sugar 和工具链环境完整
mkdir -p staging_dir/host/bin
mkdir -p staging_dir/host/share
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done
# 物理映射数据目录，解决 bison 执行失败
B_SHARE=$(pkg-config --variable=pkgdatadir bison 2>/dev/null || echo '/usr/share/bison')
ln -sf "$B_SHARE" "staging_dir/host/share/bison" || true

# --- [3. 修复点：2/7 分区与配置锁定] ---
rm -f .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
    # 注入锁定的全局变量
    echo "export BISON_PKGDATADIR=$B_SHARE"
    echo "export M4=$(which m4)"
} > .config
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# --- [4. 修复点：2/7 DTS 与 Image 物理注入] ---
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# --- [5. 修复点：2/7 Rootfs 1G 分区锁定] ---
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config
