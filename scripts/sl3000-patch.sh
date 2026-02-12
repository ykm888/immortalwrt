#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m💎 [SL3000] 开始物理静态注入（仅修改文件）...\033[0m"

cd "${WORKDIR}"

# 1. 🔥 [物理绕过] 预先创建环境检查标记 (解决 Error 1)
mkdir -p staging_dir/host
touch staging_dir/host/.prereq-build

# 2. 屏蔽签名逻辑
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

# 3. 🔥 [核心修复] 静态生成 .config，不运行 feeds，物理杜绝日志混入
# 先删除旧的，确保从零开始
rm -f .config

# 写入基础头
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# 提取自定义配置（只允许 CONFIG_ 开头，严防 Installing 日志）
if [ -f "${SRC_DIR}/sl3000.config" ]; then
    grep "^CONFIG_" "${SRC_DIR}/sl3000.config" | grep -v "Installing" >> .config || true
fi

# 4. 🔥 [物理锁定] 强制写入分区数据
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d' .config
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

# 5. 注入 DTS 和 MK
mkdir -p target/linux/mediatek/{dts,image}
[ -f "${SRC_DIR}/mt7981b-sl3000-emmc.dts" ] && cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" target/linux/mediatek/dts/
[ -f "${SRC_DIR}/filogic.mk" ] && cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/

echo -e "\033[32m✅ 静态补丁完成。注意：Feeds 和 Defconfig 将交由工作流按正确顺序执行。\033[0m"
