#!/bin/bash
set -e

# 校准路径：严格对齐 [cite: 2026-02-08]
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行补丁全量归位：物理锁定 2/5-2/9 所有验证过的设置..."

cd "${WORKDIR}"
./scripts/feeds update -a && ./scripts/feeds install -a

# 1. ✅ [严格延续] 1GB RAM 适配与 128MB 内核分区锁定 [cite: 2026-02-07]
rm -rf tmp .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
} > .config
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# 2. ✅ [严格延续] 祖传 Bison/Flex 路径修复 [cite: 2026-02-05]
mkdir -p staging_dir/host/bin
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done

# 3. ✅ [严格延续] DTS 与 filogic.mk 物理注入 [cite: 2026-02-07]
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 4. ✅ [严格延续] 物理锁定 1024MB Rootfs 分区 [cite: 2026-02-07]
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config

echo "✅ [SL3000] 补丁脚本已全量载入，无任何删减。"
