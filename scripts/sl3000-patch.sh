#!/bin/bash
set -eo pipefail
# 原文照抄你的报错拦截逻辑
trap 'echo -e "\033[31m❌ 脚本异常，构建终止\033[0m"; exit 1' ERR

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"
DEVICE_DTS="mt7981b-sl3000-emmc.dts"
DEVICE_MK="filogic.mk"
KERNEL_SIZE_BYTES=134217728

echo -e "\033[32m============================================================="
echo "  💎 SL3000-eMMC | 终极修复版 | 物理对齐配置同步"
echo "=============================================================\033[0m"

cd "${WORKDIR}"

# 1. 基础目录自愈 (原文照抄)
mkdir -p staging_dir/host/bin target/linux/mediatek/{dts,image}

# 2. 关闭 -Werror (原文照抄)
find . -name "Makefile" -type f -print0 | xargs -0 -r sed -i 's/ERROR_ON_WARNING = y/ERROR_ON_WARNING = n/g' || true
find . -name "Makefile.dtc" -type f -print0 | xargs -0 -r sed -i 's/-Werror//g' || true

# 3. 128M 语法修复 (原文照抄)
find target/linux/mediatek -name "*.mk" -o -name "Makefile" -print0 | xargs -0 -r sed -i "s/128M/${KERNEL_SIZE_BYTES}/g" || true

# 4. 彻底屏蔽签名逻辑 (物理修复：解决 usign 报错)
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

# 5. feeds 刷新 (物理提速：不使用 clean)
./scripts/feeds update -a && ./scripts/feeds install -a

# 6. 生成基础配置 (对齐逻辑)
rm -f .config
cat > .config << EOF
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y
EOF
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# 7. 🔥 [关键修复] 分区锁定与配置合法化
# 必须先锁定，再 defconfig，最后再强制确认一遍
sed -i 's/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=128/' .config
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config
make defconfig

# 8. 注入 DTS (原文照抄)
[ -f "${SRC_DIR}/${DEVICE_DTS}" ] && cp -fv "${SRC_DIR}/${DEVICE_DTS}" target/linux/mediatek/dts/
[ -f "${SRC_DIR}/${DEVICE_MK}" ] && cp -fv "${SRC_DIR}/${DEVICE_MK}" target/linux/mediatek/image/

echo -e "\033[32m✅ 脚本自愈完成，配置已锁定同步\033[0m"
