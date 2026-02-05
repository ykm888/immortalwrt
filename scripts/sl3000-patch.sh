#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 开始执行全链路逻辑对齐..."

cd "${WORKDIR}"

# 1. 优先处理 Feeds (防止后续自定义文件被 feed 覆盖)
./scripts/feeds update -a
./scripts/feeds install -a

# 2. 注入自定义镜像模具 (确保在 feeds 之后注入)
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 3. DTS 备份准备 (用于 Workflow 的 Step 6 注入)
mkdir -p "custom_files"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "custom_files/"

# 4. 工具链劫持 (针对 GitHub Actions 环境)
mkdir -p "staging_dir/host/bin"
for tool in m4 flex bison lex; do
    rm -f "staging_dir/host/bin/$tool"
    ln -sf "/usr/bin/$tool" "staging_dir/host/bin/$tool"
done
touch "staging_dir/host/.tools_install_y"

# 5. 配置文件初始化
cp -fv "${SRC_DIR}/sl3000_defconfig" .config

# 6. 【核心修复】ID 强制锁定与分区扩容
# 使用 sed 确保旧的 DEVICE 定义全部清除，防止冲突
sed -i '/CONFIG_TARGET_mediatek_filogic_DEVICE/d' .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# 锁定分区大小：内核 128M，Rootfs 1024M
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d' .config
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

# 7. 执行 defconfig 并进行存活检查
make defconfig

if grep -q "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" .config; then
    echo "✅ [Success] 设备标识符已成功锁定。"
else
    echo "❌ [Error] 配置被 make defconfig 剔除！请检查 filogic.mk 中的 Device 定义。"
    exit 1
fi

echo "✅ [Audit] 脚本逻辑对齐完成。"
