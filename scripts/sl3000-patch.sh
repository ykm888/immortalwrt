#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"
echo "💎 [SL3000] 应用全量延续补丁..."

# 1. 更新 Feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# 2. ✅ 延续：物理锁定配置与 1GB 设备识别符
rm -rf tmp .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
} > .config

# 合并用户 sl3000.config 
[ -f "${REPO_ROOT}/${SRC_DIR}/sl3000.config" ] && cat "${REPO_ROOT}/${SRC_DIR}/sl3000.config" >> .config

# 3. ✅ 延续：祖传 Bison/M4 路径修复 (2月5日修复项)
mkdir -p staging_dir/host/bin
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done

# 4. ✅ 延续：注入 DTS 和 Makefile 资产
mkdir -p "target/linux/mediatek/dts"
cp -fv "${REPO_ROOT}/${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
mkdir -p "target/linux/mediatek/image"
cp -fv "${REPO_ROOT}/${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 5. 应用配置并锁定分区大小
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

echo "✅ [SL3000] 补丁注入完成。"
