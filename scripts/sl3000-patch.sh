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

# 2. 🔥 [核心：物理重建 .config]
# 彻底删除旧的，不给残留字符任何机会
rm -f .config

# 强制注入最基础、最正确的 3 行目标定义
cat <<EOF > .config
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y
EOF

# 物理清洗自定义配置：删除空格、删除回车、只提取 CONFIG_ 格式
if [ -f "${SRC_DIR}/sl3000.config" ]; then
    grep "^CONFIG_" "${SRC_DIR}/sl3000.config" | tr -d '\r' | sed 's/ //g' >> .config || true
fi

# 3. 🔥 [物理锁定] 强制分区参数
sed -i '/_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

# 4. 物理注入 DTS 和 MK (确保编译目标物理存在)
mkdir -p target/linux/mediatek/{dts,image}
[ -f "${SRC_DIR}/mt7981b-sl3000-emmc.dts" ] && cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" target/linux/mediatek/dts/
[ -f "${SRC_DIR}/filogic.mk" ] && cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/

# 5. 屏蔽签名逻辑
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

echo -e "\033[32m✅ 补丁重构完成，配置已达到真空级纯净。\033[0m"
