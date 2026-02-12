#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m💎 [SL3000] 启动物理重构：彻底隔离污染...\033[0m"

cd "${WORKDIR}"

# 1. 物理环境准备 (解决 Error 1)
mkdir -p staging_dir/host
touch staging_dir/host/.prereq-build

# 2. 🔥 [物理重建 .config]
rm -f .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
} > .config

# 物理清洗：删除空格、删除回车、只提取 CONFIG_ 格式
if [ -f "${SRC_DIR}/sl3000.config" ]; then
    grep "^CONFIG_" "${SRC_DIR}/sl3000.config" | tr -d '\r' | sed 's/ //g' >> .config || true
fi

# 3. 🔥 [物理锁定] 强制分区参数
sed -i '/_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

# 4. 物理注入 DTS 和 MK
mkdir -p target/linux/mediatek/{dts,image}
[ -f "${SRC_DIR}/mt7981b-sl3000-emmc.dts" ] && cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" target/linux/mediatek/dts/
[ -f "${SRC_DIR}/filogic.mk" ] && cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/

# 5. 屏蔽签名逻辑
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

echo -e "\033[32m✅ 补丁重构完成。\033[0m"
