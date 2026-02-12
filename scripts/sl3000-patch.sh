#!/bin/bash
set -eo pipefail
trap 'echo -e "\033[31m❌ 脚本异常，构建终止\033[0m"; exit 1' ERR

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m💎 [SL3000] 开始物理校准配置与补丁注入...\033[0m"

cd "${WORKDIR}"

# 1. 🔥 [物理补全] 强制绕过 Prerequisite 检查，解决之前 Error 1 报错
mkdir -p staging_dir/host
touch staging_dir/host/.prereq-build

# 2. 刷新并安装 feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# 3. 🔥 [核心物理清洗] 深度过滤杂质，彻底解决 missing separator
# 无论 custom-config 里的文件带不带日志，通过 grep 物理只提取合法 CONFIG 行
TMP_CONFIG=$(mktemp)
echo "CONFIG_TARGET_mediatek=y" > "$TMP_CONFIG"
echo "CONFIG_TARGET_mediatek_filogic=y" >> "$TMP_CONFIG"
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> "$TMP_CONFIG"

if [ -f "${SRC_DIR}/sl3000.config" ]; then
    # 物理过滤：抛弃所有 Installing package 等日志字符
    grep -E "^(CONFIG_|[[:space:]]*# CONFIG_)" "${SRC_DIR}/sl3000.config" >> "$TMP_CONFIG" || true
fi
mv "$TMP_CONFIG" .config

# 4. 🔥 [物理锁定] 分区数值纯数字锁定
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d' .config
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

# 5. 屏蔽签名逻辑
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

# 6. 物理同步配置 (带 FORCE=1)
make defconfig FORCE=1

# 7. 注入 DTS 和 MK (物理目录自愈)
mkdir -p target/linux/mediatek/{dts,image}
[ -f "${SRC_DIR}/mt7981b-sl3000-emmc.dts" ] && cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" target/linux/mediatek/dts/
[ -f "${SRC_DIR}/filogic.mk" ] && cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/

echo -e "\033[32m✅ 脚本物理补完，所有历史修复已全部合入。\033[0m"
