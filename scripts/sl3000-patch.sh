#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 启动 V13 智能修复程序..."

cd "${WORKDIR}"

# 1. 延续：Feeds 同步
./scripts/feeds update -a && ./scripts/feeds install -a

# 2. 延续：劫持 Host 工具链，防止 Bison/M4 报错
mkdir -p "staging_dir/host/bin"
for tool in m4 flex bison lex; do
    rm -f "staging_dir/host/bin/$tool"
    ln -sf "/usr/bin/$tool" "staging_dir/host/bin/$tool"
done
touch "staging_dir/host/.tools_install_y"

# 3. 核心：建立安全中转站
mkdir -p "custom_files"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "custom_files/"

# 4. 延续：注入设备镜像模具 (MK)
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 5. 延续：配置初始化与强锁逻辑
cp -fv "${SRC_DIR}/sl3000_defconfig" .config

# 强锁 1GB 内存标识符与 eMMC 分区定义
sed -i '/CONFIG_TARGET_mediatek_filogic_DEVICE/d' .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d; /CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

# 6. 延续：生成最终配置并校验
make defconfig
if ! grep -q "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" .config; then
    echo "❌ 失败：配置未生效，请检查 filogic.mk 的 Device 名称！"
    exit 1
fi
echo "✅ 标识符与分区锁定成功。"
