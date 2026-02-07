#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 启动全量延续修复 (工具链补强版)..."

cd "${WORKDIR}"

# [延续修复] 1. Feeds 自愈机制
for i in {1..3}; do
    ./scripts/feeds update -a && ./scripts/feeds install -a && break || sleep 5
done

# [延续修复] 2. 环境清理与架构强锁定
rm -rf tmp .config .config.old
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# [延续修复] 3. 配置文件合并
if [ -f "${SRC_DIR}/sl3000.config" ]; then
    cat "${SRC_DIR}/sl3000.config" >> .config
else
    echo "❌ 错误：找不到 ${SRC_DIR}/sl3000.config" && exit 1
fi

# [延续修复] 4. 打包定义注入 (锁定你之前贴出的 128MB MK 配置)
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 🎯 [延续补强] 5. 核心工具链路径劫持 (解决 Error 127)
mkdir -p "staging_dir/host/bin"
# 强制将宿主机的工具链接到 staging_dir，防止打包时找不到 fwtool/opkg
for tool in m4 flex bison gawk fwtool opkg; do
    if command -v $tool >/dev/null 2>&1; then
        ln -sf "$(which $tool)" "staging_dir/host/bin/$tool"
    fi
done
touch "staging_dir/host/.tools_install_y"

# [延续修复] 6. 物理分区参数死锁
make defconfig
sed -i 's/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=128/' .config
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

echo "✅ [SL3000] 补丁注入完成，工具链路径已加固。"
