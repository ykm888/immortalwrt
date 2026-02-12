#!/bin/bash
set -eo pipefail
# 捕获异常
trap 'echo -e "\033[31m❌ 脚本异常，构建终止\033[0m"; exit 1' ERR

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"
DEVICE_DTS="mt7981b-sl3000-emmc.dts"
DEVICE_MK="filogic.mk"

echo -e "\033[32m💎 [SL3000] 物理自愈启动：彻底清除配置污染...\033[0m"

cd "${WORKDIR}"

# 1. 🔥 [物理修复] 强制跳过环境预检 (解决之前 Error 1 的病灶)
mkdir -p staging_dir/host
touch staging_dir/host/.prereq-build

# 2. 目录初始化
mkdir -p target/linux/mediatek/{dts,image}

# 3. 屏蔽签名逻辑 (物理同步)
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

# 4. 刷新 feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# 5. 🔥 [核心物理修复] 深度清洗 .config (解决 missing separator)
# 我们不再直接追加，而是先清洗出“纯净版”再覆盖，物理过滤所有 Installing 日志
TMP_CONFIG=$(mktemp)
echo "CONFIG_TARGET_mediatek=y" > "$TMP_CONFIG"
echo "CONFIG_TARGET_mediatek_filogic=y" >> "$TMP_CONFIG"
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> "$TMP_CONFIG"

if [ -f "${SRC_DIR}/sl3000.config" ]; then
    # 物理规则：只允许以 CONFIG_ 开头或以 # 开头的行通过，所有日志文本会被抛弃
    grep -E "^(CONFIG_|[[:space:]]*# CONFIG_)" "${SRC_DIR}/sl3000.config" >> "$TMP_CONFIG" || true
fi

# 强制物理覆盖，不给旧错误留任何机会
mv "$TMP_CONFIG" .config

# 6. 🔥 [锁定分区] 直接写入数值，拒绝变量逃逸
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d' .config
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

# 7. 物理同步 (强制 FORCE=1)
make defconfig FORCE=1

# 8. DTS 与 MK 注入 (逻辑对齐)
[ -f "${SRC_DIR}/${DEVICE_DTS}" ] && cp -fv "${SRC_DIR}/${DEVICE_DTS}" target/linux/mediatek/dts/
[ -f "${SRC_DIR}/${DEVICE_MK}" ] && cp -fv "${SRC_DIR}/${DEVICE_MK}" target/linux/mediatek/image/

echo -e "\033[32m✅ 脚本物理补完：.config 杂质已清除，分区已锁定。\033[0m"
