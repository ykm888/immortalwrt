#!/bin/bash
# 物理熔断
set -ex

# 物理死锁：锚定路径变量
REPO_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
WORKDIR="${REPO_ROOT}/openwrt"
CONF_SRC="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

# 1. 【专属指纹】物理修改系统标识
sed -i "s/DISTRIB_DESCRIPTION='.*'/DISTRIB_DESCRIPTION='SL-3000 Exclusive'/g" package/base-files/files/etc/openwrt_release

# 2. 【物理彻底铲平】移除 SELinux 及其所有残留警告源
find package/feeds/packages/ -name "*selinux*" -exec rm -rf {} + || true
find package/feeds/packages/ -name "*policycoreutils*" -exec rm -rf {} + || true
rm -rf package/feeds/packages/python-semanage package/system/refpolicy package/system/selinux-policy package/utils/audit package/utils/policycoreutils package/libs/libsemanage package/boot/arm-trusted-firmware-microchipsw || true

# 3. 【三件套物理注入与新版引导锁定】
rm -f .config*
if [ -f "${CONF_SRC}/sl3000.config" ]; then
    cp -fv "${CONF_SRC}/sl3000.config" .config
    
    # 物理瘦身：关闭 Debug 和 Rust 确保不超时
    sed -i 's/CONFIG_DEBUG_INFO=y/n/g' .config || echo "CONFIG_DEBUG_INFO=n" >> .config
    sed -i 's/CONFIG_KERNEL_DEBUG_INFO=y/n/g' .config || echo "CONFIG_KERNEL_DEBUG_INFO=n" >> .config
    echo "CONFIG_RUST_SUPPORT=n" >> .config
    
    # 🔥 物理修复：强制开启 24.10 适配的新版引导程序编译
    echo "CONFIG_TARGET_mediatek=y" >> .config
    echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config
    echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
    echo "CONFIG_PACKAGE_atf-mt7981=y" >> .config
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y" >> .config
fi

# 4. 【路径锚定】
DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_DIR"
[ -f "${CONF_SRC}/mt7981b-3000-emmc.dts" ] && cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$DTS_DIR/"
[ -f "${CONF_SRC}/filogic.mk" ] && cp -fv "${CONF_SRC}/filogic.mk" "target/linux/mediatek/image/filogic.mk"
