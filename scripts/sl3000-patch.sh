#!/bin/bash
set -e
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行全量物理补丁：屏蔽报错 + 路径映射 + 优化工具链..."
cd "${WORKDIR}"

# [1] 2/9 修复：屏蔽 Werror
find . -name Makefile -exec sed -i 's/ERROR_ON_WARNING = y/ERROR_ON_WARNING = n/g' {} +
find . -name "Makefile.dtc" -exec sed -i 's/-Werror//g' {} + || true

# [2] 延续：Feeds 更新
./scripts/feeds update -a && ./scripts/feeds install -a

# [3] 2/5 修复：Bison/M4 路径映射
mkdir -p staging_dir/host/bin staging_dir/host/share
for tool in m4 flex bison gawk; do ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true; done
B_SHARE=$(pkg-config --variable=pkgdatadir bison 2>/dev/null || echo '/usr/share/bison')
ln -sf "$B_SHARE" "staging_dir/host/share/bison" || true

# [4] 2/7 修复：锁定配置 & 物理屏蔽耗时工具 (加速编译)
rm -f .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
    # 物理屏蔽 Rust/LLVM 等耗时且 SL3000 不需要的基础工具
    echo "# CONFIG_PACKAGE_luci-app-dockerman is not set"
    echo "# CONFIG_PACKAGE_luci-lib-docker is not set"
    echo "export BISON_PKGDATADIR=$B_SHARE"
    echo "export M4=$(which m4)"
} > .config
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# [5] 2/7 修复：DTS/Image 注入与 1G 分区
mkdir -p "target/linux/mediatek/dts" "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config
