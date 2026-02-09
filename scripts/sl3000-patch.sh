#!/bin/bash
set -e

# 校准根路径：严格防止双重路径拼接 [cite: 2026-02-08]
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 应用终极版补丁 (物理找回所有历史修复)..."

cd "${WORKDIR}"
./scripts/feeds update -a && ./scripts/feeds install -a

# 1. ✅ [延续历史设置] 物理锁定 1GB RAM 与 128MB 内核分区 [cite: 2026-02-06, 2026-02-07]
rm -rf tmp .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
} > .config
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# 2. ✅ [延续历史设置] 祖传 Bison/Flex 路径修复 [cite: 2026-02-05]
mkdir -p staging_dir/host/bin
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done

# 3. ✅ [延续历史设置] 注入 DTS 和核心 filogic.mk [cite: 2026-02-06, 2026-02-07]
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"

mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 4. ✅ [延续历史设置] 物理锁定 1024MB Rootfs 分区 [cite: 2026-02-07]
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config

echo "✅ [SL3000] 补丁恢复成功。128M/1024M/1G RAM 配置已全部归位。"
