#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 启动终极修复程序..."

cd "${WORKDIR}"

# 1. 延续：Feeds 优先，防止官方库覆盖自定义修改
./scripts/feeds update -a && ./scripts/feeds install -a

# 2. 延续：彻底劫持工具链，解决 bison/m4 找不到的问题
mkdir -p "staging_dir/host/bin"
for tool in m4 flex bison lex; do
    rm -f "staging_dir/host/bin/$tool"
    ln -sf "/usr/bin/$tool" "staging_dir/host/bin/$tool"
done
touch "staging_dir/host/.tools_install_y"

# 3. 核心：建立安全中转站，存放你的 DTS 文件
mkdir -p "custom_files"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "custom_files/"

# 4. 延续：注入设备模具
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 5. 延续：配置初始化与 ID/分区强锁
cp -fv "${SRC_DIR}/sl3000_defconfig" .config
sed -i '/CONFIG_TARGET_mediatek_filogic_DEVICE/d' .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d; /CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

# 6. 延续：存活检查，确保配置没被剔除
make defconfig
if ! grep -q "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" .config; then
    echo "❌ 失败：配置被系统自动删除，请检查 filogic.mk 内容！"
    exit 1
fi
echo "✅ 标识符锁定成功！"
