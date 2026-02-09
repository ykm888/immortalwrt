#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行物理全量修复：合并所有历史验证补丁，锁定构建地基..."

cd "${WORKDIR}"

# [延续修复 1：2/9] 屏蔽所有 Makefile 中的 -Werror (物理解决 DTC/Binutils 报错)
find . -name Makefile -exec sed -i 's/ERROR_ON_WARNING = y/ERROR_ON_WARNING = n/g' {} +
find . -name "Makefile.dtc" -exec sed -i 's/-Werror//g' {} + || true
find . -name "Makefile*" -exec sed -i 's/-Werror//g' {} + || true

# [延续设置] Feeds 更新与安装
./scripts/feeds update -a && ./scripts/feeds install -a

# [延续修复 2：2/5] Bison/M4 路径映射 (物理建立 share 映射，确保核心宏不丢失)
mkdir -p staging_dir/host/bin staging_dir/host/share
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done
B_SHARE=$(pkg-config --variable=pkgdatadir bison 2>/dev/null || echo '/usr/share/bison')
ln -sf "$B_SHARE" "staging_dir/host/share/bison" || true

# [物理对齐 3] 2/7 锁定内核分区 128MB 与物理环境变量锁
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

# [延续修复 4：2/7] DTS 与 Image 物理注入 (SL3000 适配核心)
mkdir -p "target/linux/mediatek/dts" "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# [延续修复 5：2/7] Rootfs 1G 分区锁定
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config
