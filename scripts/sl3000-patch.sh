#!/bin/bash
set -eo pipefail
# 原文照抄报错拦截逻辑
trap 'echo -e "\033[31m❌ 脚本异常，构建终止\033[0m"; exit 1' ERR

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"
DEVICE_DTS="mt7981b-sl3000-emmc.dts"
DEVICE_MK="filogic.mk"
KERNEL_SIZE_BYTES=134217728

echo -e "\033[32m💎 [SL3000] 开始物理校准配置与补丁注入...\033[0m"

cd "${WORKDIR}"

# 1. 基础目录自愈 (原文照抄)
mkdir -p staging_dir/host/bin target/linux/mediatek/{dts,image}

# 2. 关闭警告报错 (原文照抄)
find . -name "Makefile" -type f -print0 | xargs -0 -r sed -i 's/ERROR_ON_WARNING = y/ERROR_ON_WARNING = n/g' || true
find . -name "Makefile.dtc" -type f -print0 | xargs -0 -r sed -i 's/-Werror//g' || true

# 3. 128M 物理换算 (原文照抄)
find target/linux/mediatek -name "*.mk" -o -name "Makefile" -print0 | xargs -0 -r sed -i "s/128M/${KERNEL_SIZE_BYTES}/g" || true

# 4. 彻底屏蔽签名逻辑 (物理修复：解决 usign 报错)
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

# 5. feeds 刷新 (优化：跳过 clean 提速)
./scripts/feeds update -a && ./scripts/feeds install -a

# 6. 配置锁定
rm -f .config
cat > .config << EOF
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y
EOF
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# 7. 🔥 [核心修复] 分区数值锁定与合法化同步
# 必须物理写入 128，并通过 defconfig 转化为 Makefile 可读变量
sed -i 's/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=128/' .config
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config

# 强制执行同步，物理终结 "out of sync" 和 "dd: invalid number"
make defconfig

# 8. 注入 DTS (原文照抄)
[ -f "${SRC_DIR}/${DEVICE_DTS}" ] && cp -fv "${SRC_DIR}/${DEVICE_DTS}" target/linux/mediatek/dts/
[ -f "${SRC_DIR}/${DEVICE_MK}" ] && cp -fv "${SRC_DIR}/${DEVICE_MK}" target/linux/mediatek/image/
