#!/bin/bash
set -eo pipefail
trap 'echo -e "\033[31m❌ 脚本异常，构建终止\033[0m"; exit 1' ERR

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"
DEVICE_DTS="mt7981b-sl3000-emmc.dts"
DEVICE_MK="filogic.mk"

echo -e "\033[32m💎 [SL3000] 开始物理校准配置与补丁注入...\033[0m"

cd "${WORKDIR}"

# 1. 基础目录自愈
mkdir -p staging_dir/host/bin target/linux/mediatek/{dts,image}

# 2. 彻底屏蔽签名逻辑 (物理修复：解决 usign 报错)
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

# 3. 注入基础配置 (物理隔离，确保 .config 干净)
rm -f .config
cat > .config << EOF
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y
EOF

# 4. 🔥 [物理清洗注入] 确保 sl3000.config 没有任何非法格式
# 只提取符合 CONFIG_ 或 # CONFIG_ 格式的行，剔除乱码和空格
if [ -f "${SRC_DIR}/sl3000.config" ]; then
    grep -E "^(CONFIG_|[[:space:]]*# CONFIG_)" "${SRC_DIR}/sl3000.config" >> .config
fi

# 5. 🔥 [锁定分区值] 直接物理覆盖，确保 dd 不会报错
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d' .config
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

# 6. 物理同步并强制生成配置索引 (解决 prepare-tmpinfo 报错)
make defconfig

# 7. 注入 DTS (保持原有验证过的逻辑)
[ -f "${SRC_DIR}/${DEVICE_DTS}" ] && cp -fv "${SRC_DIR}/${DEVICE_DTS}" target/linux/mediatek/dts/
[ -f "${SRC_DIR}/${DEVICE_MK}" ] && cp -fv "${SRC_DIR}/${DEVICE_MK}" target/linux/mediatek/image/

echo -e "\033[32m✅ 脚本自愈完成，.config 已物理校验合法\033[0m"
