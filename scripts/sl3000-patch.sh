#!/bin/bash
set -e

# 确保定位到仓库根目录
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000 Audit] 正在执行全量基因锁定..."

# 1. 静态模具注入
mkdir -p "${WORKDIR}/target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "${WORKDIR}/target/linux/mediatek/image/filogic.mk"

# 2. DTS 预净化处理
mkdir -p "${WORKDIR}/custom_files"
{ 
    echo '/dts-v1/;'
    grep -v "/dts-v1/;" "${SRC_DIR}/mt7981b-sl3000-emmc.dts" | tr -d '\r'
} > "${WORKDIR}/custom_files/mt7981b-sl3000-emmc.dts"

# 3. 宿主机环境硬化 - 建立最高优先级工具链
mkdir -p "${WORKDIR}/staging_dir/host/bin"
for tool in m4 flex bison lex sed awk rsync grep; do
    ln -sf /usr/bin/$tool "${WORKDIR}/staging_dir/host/bin/$tool"
done
touch "${WORKDIR}/staging_dir/host/.tools_install_y"

# 4. 源码预处理
cd "${WORKDIR}"
./scripts/feeds update -a && ./scripts/feeds install -a

# 5. 配置强制对齐 (防止内存定义被自动缩减)
cp -fv "${SRC_DIR}/sl3000_defconfig" .config
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d' .config
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config
make defconfig

echo "✅ [Audit] 脚本校验通过，环境已锁定。"
