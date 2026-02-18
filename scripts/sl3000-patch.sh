#!/bin/bash
# 物理熔断：开启全量追踪与错误即停
set -ex

# 物理死锁：锚定路径变量
REPO_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
WORKDIR="${REPO_ROOT}/openwrt"
# 物理三件套源目录
CONF_SRC="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

# 1. 体系延续：物理铲平冲突项 (解决 24.10 依赖断裂)
rm -rf package/libs/libsemanage || true
rm -rf package/feeds/packages/python-semanage || true
rm -rf package/boot/arm-trusted-firmware-microchipsw || true
rm -rf package/utils/audit || true
rm -rf package/emortal/autosamba || true
rm -rf package/utils/policycoreutils || true
rm -rf package/system/refpolicy || true
rm -rf package/system/selinux-policy || true

# 2. 三件套物理注入：Config (custom-config/sl3000.config)
if [ -f "${CONF_SRC}/sl3000.config" ]; then
    cp -fv "${CONF_SRC}/sl3000.config" .config
    # 物理强制：确保包名与 Makefile 逻辑死锁
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config
    echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
    echo "CONFIG_PACKAGE_atf-mt7981=y" >> .config
fi

# 3. 三件套物理注入：DTS (custom-config/mt7981b-3000-emmc.dts)
DTS_TARGET_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_TARGET_DIR"
if [ -f "${CONF_SRC}/mt7981b-3000-emmc.dts" ]; then
    cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$DTS_TARGET_DIR/"
fi

# 核心自愈：物理补全 build_dir
if [ -d "build_dir" ]; then
    find build_dir/ -type d -path "*/arch/arm64/boot/dts/mediatek" | while read -r dts_path; do
        cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$dts_path/"
    done
fi

# 4. 三件套物理注入：Makefile (custom-config/filogic.mk)
MK_TARGET="target/linux/mediatek/image/filogic.mk"
if [ -f "${CONF_SRC}/filogic.mk" ]; then
    cp -fv "${CONF_SRC}/filogic.mk" "$MK_TARGET"
fi
