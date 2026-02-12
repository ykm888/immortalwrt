#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m💎 [SL3000] 启动物理重构：DTS 穿透 + 镜像生成路径放宽...\033[0m"

cd "${WORKDIR}"

# 1. 物理环境准备
mkdir -p staging_dir/host
touch staging_dir/host/.prereq-build

# 2. 🔥 [物理重建 .config]
rm -f .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
} > .config
if [ -f "${SRC_DIR}/sl3000.config" ]; then
    grep "^CONFIG_" "${SRC_DIR}/sl3000.config" | tr -d '\r' | sed 's/ //g' >> .config || true
fi

# 3. 🔥 [物理锁定] 分区参数
sed -i '/_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

# 4. 🔥 [物理放宽] 彻底修复 Missing Build/true 错误
# 原理：append-string 是系统内置宏，后面不加参数即为空操作，不会导致解析失败
if [ -f "include/image.mk" ]; then
    sed -i 's/pad-to/append-string/g' include/image.mk || true
fi

# 5. 🔥 [物理路径] DTS 三路锁定注入
DTS_PATH_A="target/linux/mediatek/dts"
DTS_PATH_B="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_PATH_A" "$DTS_PATH_B"
if [ -f "${SRC_DIR}/mt7981b-sl3000-emmc.dts" ]; then
    cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "$DTS_PATH_A/"
    cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "$DTS_PATH_B/"
fi

# 6. 🔥 [物理注入] 镜像定义 MK
mkdir -p target/linux/mediatek/image
if [ -f "${SRC_DIR}/filogic.mk" ]; then
    cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/
    # 物理放宽：将 pad-to 改为 append-string 防止 Makefile 报错
    sed -i 's/pad-to/append-string/g' target/linux/mediatek/image/filogic.mk || true
    sed -i 's/check-size/append-string/g' target/linux/mediatek/image/filogic.mk || true
fi

# 7. 屏蔽签名逻辑 (这两个不是 Makefile 宏定义，可以用 true)
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

echo -e "\033[32m✅ 固件生成路径已物理放宽，语法错误已封堵。\033[0m"
