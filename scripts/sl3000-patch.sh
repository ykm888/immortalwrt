#!/bin/bash
set -e

# 定位路径
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000 Final Audit] 正在执行工具链硬链接与基因锁定..."

# 1. 注入镜像生成规则
mkdir -p "${WORKDIR}/target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "${WORKDIR}/target/linux/mediatek/image/filogic.mk"

# 2. 构造无损 DTS
mkdir -p "${WORKDIR}/custom_files"
{ 
    echo '/dts-v1/;'
    grep -v "/dts-v1/;" "${SRC_DIR}/mt7981b-sl3000-emmc.dts" | tr -d '\r'
} > "${WORKDIR}/custom_files/mt7981b-sl3000-emmc.dts"

# 3. 【核心修复】强制劫持工具链并伪装状态
mkdir -p "${WORKDIR}/staging_dir/host/bin"
mkdir -p "${WORKDIR}/staging_dir/host/stamp"

# 物理删除并强制软链到宿主机 Ubuntu 系统工具
for tool in m4 flex bison lex; do
    rm -f "${WORKDIR}/staging_dir/host/bin/$tool"
    ln -sf "/usr/bin/$tool" "${WORKDIR}/staging_dir/host/bin/$tool"
    # 制造假的时间戳，骗过 Makefile 让它以为这些工具已经编译安装过了
    touch "${WORKDIR}/staging_dir/host/stamp/.$tool_installed"
done

touch "${WORKDIR}/staging_dir/host/.tools_install_y"

# 4. 同步 Feeds 并注入配置
cd "${WORKDIR}"
./scripts/feeds update -a && ./scripts/feeds install -a
cp -fv "${SRC_DIR}/sl3000_defconfig" .config

# 强制注入分区大小限制
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d; /CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

make defconfig

echo "✅ [Final Audit] 工具链硬化完成。"
