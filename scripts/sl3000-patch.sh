#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 启动全量延续修复脚本 (严禁漂移版)..."

cd "${WORKDIR}"

# [延续修复] 1. Feeds 自愈：确保源码包下载完整
for i in {1..3}; do
    ./scripts/feeds update -a && ./scripts/feeds install -a && break || sleep 5
done

# [延续修复] 2. 身份锁定：防止架构漂移到 x86
rm -rf tmp .config .config.old
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# [延续修复] 3. 配置文件合并：精准载入你修好的 sl3000.config
cat "${SRC_DIR}/sl3000.config" >> .config

# [延续修复] 4. 打包文件注入：强行覆盖，守住 pad-to 128MB 的 filogic.mk
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# [延续修复] 5. 工具链劫持：解决 GitHub Actions 宿主机 bison/m4 冲突
mkdir -p "staging_dir/host/bin"
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool"
done
touch "staging_dir/host/.tools_install_y"

# [延续修复] 6. 物理参数硬锁定：死守 128M 内核分区与 512M RootFS (终结 Error 1)
make defconfig
sed -i 's/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=128/' .config
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

echo "✅ [SL3000] 补丁注入完成，所有之前修复的工程参数已锁定。"
