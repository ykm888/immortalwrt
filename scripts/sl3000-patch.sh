#!/bin/bash
set -e

# 定位根目录
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000 Pro Max+] 正在注入终极基因..."

# 1. 注入镜像模具
mkdir -p "${WORKDIR}/target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "${WORKDIR}/target/linux/mediatek/image/filogic.mk"

# 2. 构造无损 DTS
mkdir -p "${WORKDIR}/custom_files"
{ echo '/dts-v1/;' ; grep -v "/dts-v1/;" "${SRC_DIR}/mt7981b-sl3000-emmc.dts" | tr -d '\r' ; } > "${WORKDIR}/custom_files/mt7981b-sl3000-emmc.dts"

# 3. 环境硬化
mkdir -p "${WORKDIR}/staging_dir/host/bin"
for tool in m4 flex bison lex sed awk rsync grep; do
    ln -sf /usr/bin/$tool "${WORKDIR}/staging_dir/host/bin/$tool"
done

# 4. 同步 Feeds
cd "${WORKDIR}"
./scripts/feeds update -a && ./scripts/feeds install -a

# 5. 配置锁定
cp -fv "${SRC_DIR}/sl3000_defconfig" .config
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d; /CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config
echo "CONFIG_CCACHE=y" >> .config
make defconfig

echo "✅ 注入完成。"
