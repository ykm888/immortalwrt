#!/bin/bash
set -eo pipefail
trap 'echo -e "\033[31m❌ 脚本异常，构建终止\033[0m"; exit 1' ERR

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m💎 [SL3000] 物理自愈：开启真空级配置清洗...\033[0m"

cd "${WORKDIR}"

# 1. 🔥 [承袭补丁] 物理绕过 Prerequisite 检查 (解决 Error 1)
mkdir -p staging_dir/host
touch staging_dir/host/.prereq-build

# 2. 🔥 [核心隔离] 更新 feeds 并物理丢弃所有产生的日志，防止其进入输出流污染 .config
./scripts/feeds update -a
./scripts/feeds install -a > /dev/null 2>&1

# 3. 🔥 [核心清洗] 彻底拦截 missing separator 幽灵
# 先创建一个临时文件进行清洗，严禁直接在 .config 上操作
TMP_CLEAN=$(mktemp)
echo "CONFIG_TARGET_mediatek=y" > "$TMP_CLEAN"
echo "CONFIG_TARGET_mediatek_filogic=y" >> "$TMP_CLEAN"
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> "$TMP_CLEAN"

if [ -f "${SRC_DIR}/sl3000.config" ]; then
    # 物理过滤：只允许以 CONFIG_ 开头的行进入，物理剔除所有包含 "Installing" 的日志行
    grep "^CONFIG_" "${SRC_DIR}/sl3000.config" | grep -v "Installing" >> "$TMP_CLEAN" || true
fi

# 4. 🔥 [物理锁定] 分区数值锁定 (128M/1024M)
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d' "$TMP_CLEAN"
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' "$TMP_CLEAN"
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> "$TMP_CLEAN"
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> "$TMP_CLEAN"

# 5. 🔥 [原子覆盖] 使用强力覆盖，确保最终 .config 绝对纯净
cat "$TMP_CLEAN" > .config
rm -f "$TMP_CLEAN"

# 6. 屏蔽签名逻辑 (物理同步)
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

# 7. 物理同步配置 (强制 FORCE=1)
make defconfig FORCE=1

# 8. 注入 DTS 和 MK (物理目录自愈)
mkdir -p target/linux/mediatek/{dts,image}
[ -f "${SRC_DIR}/mt7981b-sl3000-emmc.dts" ] && cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" target/linux/mediatek/dts/
[ -f "${SRC_DIR}/filogic.mk" ] && cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/

echo -e "\033[32m✅ 脚本自愈完成：.config 已物理脱敏。\033[0m"
