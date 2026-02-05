#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 正在执行全量修复逻辑对齐 (延续所有历史补丁)..."

cd "${WORKDIR}"

# 1. 优先处理 Feeds (延续修复：确保自定义模具不会被 feed 覆盖)
./scripts/feeds update -a
./scripts/feeds install -a

# 2. 注入自定义镜像模具 (延续修复：路径锁定为 sl3000-emmc)
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 3. 【核心延续】DTS 中转准备
# 必须创建此目录，Workflow 的 Step 6 才能从中提取 DTS 注入内核
mkdir -p "custom_files"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "custom_files/"

# 4. 【核心延续】工具链劫持 (彻底根治 bison 报错)
# 之前的设置：强行让 OpenWrt 使用宿主机最稳的 bison/m4
mkdir -p "staging_dir/host/bin"
for tool in m4 flex bison lex; do
    rm -f "staging_dir/host/bin/$tool"
    ln -sf "/usr/bin/$tool" "staging_dir/host/bin/$tool"
done
# 欺骗编译系统，告诉它 host 工具已经“安装”好了
touch "staging_dir/host/.tools_install_y"

# 5. 配置文件初始化
cp -fv "${SRC_DIR}/sl3000_defconfig" .config

# 6. 【核心延续】ID 锁定与分区容量强锁
# 确保 ID 绝对是 sl3000-emmc，防止被默认配置带偏
sed -i '/CONFIG_TARGET_mediatek_filogic_DEVICE/d' .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# 延续之前的分区设置：128M KERNEL + 1G Rootfs
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d' .config
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

# 7. 执行并检查 (延续修复：防止配置被静默剔除)
make defconfig

if grep -q "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" .config; then
    echo "✅ [Success] 标识符 sl3000-emmc 已锁定，配置存活。"
else
    echo "❌ [Error] 配置被 make defconfig 剔除！请检查 filogic.mk 定义。"
    exit 1
fi

echo "✅ [Audit] 脚本全量修复逻辑执行完毕。"
