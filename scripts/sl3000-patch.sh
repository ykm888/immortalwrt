#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 启动 V13.1 注入修复..."

cd "${WORKDIR}"

# 1. 更新 Feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# 2. 劫持 Host 工具防止冲突
mkdir -p "staging_dir/host/bin"
for tool in m4 flex bison lex; do
    rm -f "staging_dir/host/bin/$tool"
    ln -sf "/usr/bin/$tool" "staging_dir/host/bin/$tool"
done
touch "staging_dir/host/.tools_install_y"

# 3. 准备自定义文件
mkdir -p "custom_files"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "custom_files/"

# 4. 注入设备镜像定义 (MK)
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 5. 强锁 1GB 内存配置
cp -fv "${SRC_DIR}/sl3000_defconfig" .config
sed -i '/CONFIG_TARGET_mediatek_filogic_DEVICE/d' .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config
# 分区锁定
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d; /CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

make defconfig
echo "✅ 注入完成。"
