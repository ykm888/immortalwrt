#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

echo "💎 [SL3000] 开始完整补丁注入..."

# 1. 物理清理残留
rm -rf tmp .config .config.old

# 2. Feeds 处理
./scripts/feeds update -a && ./scripts/feeds install -a

# 3. 强制架构锁定 (解决 x86 污染)
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# 4. 载入 1GB 内存与 eMMC 配置
if [ -f "${SRC_DIR}/sl3000_defconfig" ]; then
    # 强制修改 defconfig 里的内核分区大小为 128
    sed -i 's/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=128/' "${SRC_DIR}/sl3000_defconfig"
    cat "${SRC_DIR}/sl3000_defconfig" >> .config
fi

# 5. 设备定义注入
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"
mkdir -p "custom_files"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "custom_files/"

# 6. Host 工具劫持 (延续之前修复)
mkdir -p "staging_dir/host/bin"
ln -sf "/usr/bin/m4" "staging_dir/host/bin/m4"
ln -sf "/usr/bin/flex" "staging_dir/host/bin/flex"
ln -sf "/usr/bin/bison" "staging_dir/host/bin/bison"
touch "staging_dir/host/.tools_install_y"

make defconfig

# 架构校验
if grep -q "CONFIG_TARGET_x86=y" .config; then
    echo "❌ 架构锁定失败！" && exit 1
fi
echo "✅ 补丁注入成功。"
