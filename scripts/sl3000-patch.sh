#!/bin/bash
# 物理熔断：开启全量追踪与错误即停
set -ex

# 物理死锁：锚定路径变量
REPO_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
WORKDIR="${REPO_ROOT}/openwrt"
# 物理三件套源目录：必须位于 custom-config/
CONF_SRC="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

# 1. 体系延续：全链路依赖清理（解决 24.10 报错）
# 物理清理导致 Dependency Break 的源头
rm -rf package/libs/libsemanage || true
rm -rf package/feeds/packages/python-semanage || true
rm -rf package/boot/arm-trusted-firmware-microchipsw || true
rm -rf package/utils/audit || true
rm -rf package/emortal/autosamba || true
rm -rf package/utils/policycoreutils || true
rm -rf package/utils/pcat-manager || true
rm -rf package/system/refpolicy || true
rm -rf package/system/selinux-policy || true

# 2. 三件套物理注入：Config (custom-config/sl3000.config)
if [ -f "${CONF_SRC}/sl3000.config" ]; then
    cp -fv "${CONF_SRC}/sl3000.config" .config
    # 强制物理同步：补齐 24.10 分支下的 ATF 和 U-Boot 包名
    echo "CONFIG_PACKAGE_u-boot-sl3000-emmc=y" >> .config
    echo "CONFIG_PACKAGE_atf-mt7981-sl3000-emmc=y" >> .config
fi

# 3. 三件套物理注入：DTS (custom-config/mt7981b-3000-emmc.dts)
# 物理路径锁定：24.10 默认使用内核 6.6
DTS_TARGET_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_TARGET_DIR"
if [ -f "${CONF_SRC}/mt7981b-3000-emmc.dts" ]; then
    cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$DTS_TARGET_DIR/"
fi

# 核心自愈：物理补全 build_dir，确保交叉编译时 DTS 被内核正确调用
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
