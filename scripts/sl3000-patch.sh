#!/bin/bash
set -e

# 设置绝对路径，防止双重拼接 [cite: 2026-02-08]
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 正在应用路径修复版补丁..."

cd "${WORKDIR}"

# 1. 更新 Feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# 2. ✅ 延续：物理锁定 1GB 设备识别符
rm -rf tmp .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
} > .config

# 合并用户配置
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# 3. ✅ 延续：祖传 Bison/M4 路径修复
mkdir -p staging_dir/host/bin
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done

# 4. ✅ 修复：路径注入逻辑 (关键修复点)
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"

mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 5. 应用配置
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

echo "✅ [SL3000] 补丁注入完成，路径已校准。"
