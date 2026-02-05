#!/bin/bash
set -e

# 定位根目录
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000 Pro Max+] 正在注入终极内核补丁基因..."

# 1. 静态模具注入
mkdir -p "${WORKDIR}/target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "${WORKDIR}/target/linux/mediatek/image/filogic.mk"

# 2. 构造“无损”DTS
mkdir -p "${WORKDIR}/custom_files"
{ echo '/dts-v1/;' ; grep -v "/dts-v1/;" "${SRC_DIR}/mt7981b-sl3000-emmc.dts" | tr -d '\r' ; } > "${WORKDIR}/custom_files/mt7981b-sl3000-emmc.dts"

# 3. 宿主机依赖硬化
mkdir -p "${WORKDIR}/staging_dir/host/bin"
for tool in m4 flex bison lex sed awk rsync grep; do
    ln -sf /usr/bin/$tool "${WORKDIR}/staging_dir/host/bin/$tool"
done

# 4. 源码初始化与 Feeds 锁定
cd "${WORKDIR}"
./scripts/feeds update -a && ./scripts/feeds install -a

# 5. 配置硬核对齐
cp -fv "${SRC_DIR}/sl3000_defconfig" .config
# 物理锁定分区大小，不给系统回滚机会
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d; /CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config
# 开启编译加速选项
echo "CONFIG_CCACHE=y" >> .config

make defconfig

echo "✅ [Pro Max+] 基因重组完成，等待极速构建。"
