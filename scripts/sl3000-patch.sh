#!/bin/bash
set -e
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行物理修复：全量补丁归位 + 宿主工具路径锁定..."
cd "${WORKDIR}"

# [1] 延续 2/9 修复：物理屏蔽 Werror
find . -name Makefile -exec sed -i 's/ERROR_ON_WARNING = y/ERROR_ON_WARNING = n/g' {} +
find . -name "Makefile.dtc" -exec sed -i 's/-Werror//g' {} + || true

# [2] 延续：Feeds 管理
./scripts/feeds update -a && ./scripts/feeds install -a

# [3] 延续 2/5 修复：Bison/M4 路径映射与环境变量
mkdir -p staging_dir/host/bin staging_dir/host/share
for tool in m4 flex bison gawk; do ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true; done
B_SHARE=$(pkg-config --variable=pkgdatadir bison 2>/dev/null || echo '/usr/share/bison')
ln -sf "$B_SHARE" "staging_dir/host/share/bison" || true

# [4] 🔥 [新增物理修复] 锁定 opkg-host 路径，防止 Error 127
# 这一步确保 package/install 找不到 opkg 时有物理备份
mkdir -p staging_dir/host/bin
[ -f /usr/bin/opkg ] && ln -sf /usr/bin/opkg staging_dir/host/bin/opkg || true

# [5] 延续 2/7 修复：锁定 128MB 内核与分区配置
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

# [6] 延续 2/7 修复：DTS/Image 注入与 1G 分区锁定
mkdir -p "target/linux/mediatek/dts" "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config
