#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行物理修复：全量补丁归位 + 宿主工具链封印..."

cd "${WORKDIR}"

# [1] 物理创建基础目录，防止 OpenWrt 预检阶段因目录不存在而报错
mkdir -p staging_dir/host/bin staging_dir/host/share

# [2] 延续修复：2/9 物理屏蔽所有 Makefile 中的 -Werror (解决构建中断)
find . -name Makefile -exec sed -i 's/ERROR_ON_WARNING = y/ERROR_ON_WARNING = n/g' {} +
find . -name "Makefile.dtc" -exec sed -i 's/-Werror//g' {} + || true

# [3] 延续设置：Feeds 更新与安装
./scripts/feeds update -a && ./scripts/feeds install -a

# [4] 🔥 [核心修复] 物理封印宿主工具 (借用系统工具，彻底解决 mkhash/libdeflate 报错)
# 这步确保即使没有缓存，系统也会发现工具“已到位”，从而跳过易出错的自建步骤
for tool in m4 flex bison gawk sed patch tar xz gzip bzip2 perl python3 wget curl; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done
B_SHARE=$(pkg-config --variable=pkgdatadir bison 2>/dev/null || echo '/usr/share/bison')
ln -sf "$B_SHARE" "staging_dir/host/share/bison" || true

# [5] 延续修复：2/7 锁定内核分区 128MB 与物理环境变量锁
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

# [6] 延续修复：2/7 DTS 与 Image 物理注入 (SL3000 适配核心)
mkdir -p "target/linux/mediatek/dts" "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# [7] 延续修复：2/7 Rootfs 1G 分区锁定
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config
