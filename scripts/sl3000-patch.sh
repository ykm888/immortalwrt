#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 正在执行最后的逻辑对齐..."

# 1. 注入镜像模具
mkdir -p "${WORKDIR}/target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "${WORKDIR}/target/linux/mediatek/image/filogic.mk"

# 2. DTS 准备
mkdir -p "${WORKDIR}/custom_files"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "${WORKDIR}/custom_files/"

# 3. 工具链劫持 (彻底根治 bison 报错)
mkdir -p "${WORKDIR}/staging_dir/host/bin"
for tool in m4 flex bison lex; do
    rm -f "${WORKDIR}/staging_dir/host/bin/$tool"
    ln -sf "/usr/bin/$tool" "${WORKDIR}/staging_dir/host/bin/$tool"
done
touch "${WORKDIR}/staging_dir/host/.tools_install_y"

# 4. 配置初始化与 ID 强行对齐
cd "${WORKDIR}"
./scripts/feeds update -a && ./scripts/feeds install -a
cp -fv "${SRC_DIR}/sl3000_defconfig" .config

# 【核心修复】确保勾选 sl3000-emmc 并锁定分区大小
sed -i '/CONFIG_TARGET_mediatek_filogic_DEVICE/d' .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d; /CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

make defconfig

echo "✅ [Audit] 脚本执行完毕，标识符已锁定为 sl3000-emmc。"
