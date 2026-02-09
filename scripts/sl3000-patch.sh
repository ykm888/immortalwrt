#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行物理补丁全量归位：严禁漏改，恢复所有历史修复..."

cd "${WORKDIR}"
# ✅ [延续设置] 仅更新 feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# 1. 🔥 [物理还原] 解决 toolchain/binutils 编译报错 (2/9 修复点)
if [ -f "toolchain/binutils/Makefile" ]; then
    sed -i 's/ERROR_ON_WARNING = y/ERROR_ON_WARNING = n/' toolchain/binutils/Makefile
    echo "✅ [补丁归位] binutils 警告屏蔽已锁定"
fi

# 2. ✅ [延续设置] 物理锁定 128MB 内核与 1G RAM
rm -f .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
} > .config
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# 3. ✅ [延续设置] 物理修复 Bison/Flex 路径 (2/5 修复)
mkdir -p staging_dir/host/bin
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done

# 4. ✅ [延续设置] DTS 与 filogic.mk 物理预置 (2/7 修复)
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 5. ✅ [物理锁定] 延续 1024MB Rootfs 锁定逻辑
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config
