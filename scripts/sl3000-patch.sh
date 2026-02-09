#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行补丁全量归位：物理锁定 2/5-2/9 所有验证过的设置..."

cd "${WORKDIR}"
# ✅ [延续设置] 仅更新 feeds，严禁清理已有的构建环境
./scripts/feeds update -a && ./scripts/feeds install -a

# 1. ✅ [延续设置] 物理锁定 128MB 内核分区与 1G RAM 适配
rm -rf tmp .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
} > .config
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# 2. ✅ [延续设置] 物理修复 Bison/Flex 路径 (2/5 补丁)
mkdir -p staging_dir/host/bin
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done

# 3. ✅ [延续设置] DTS 与 filogic.mk 物理注入 (2/7 补丁)
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 4. ✅ [延续设置] 物理锁定 1024MB Rootfs 根分区
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config

echo "✅ [SL3000] 补丁脚本已全量载入，无任何删减。"
