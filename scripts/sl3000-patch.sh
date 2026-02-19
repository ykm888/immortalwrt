#!/bin/bash
# 物理熔断
set -ex

REPO_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
WORKDIR="${REPO_ROOT}/openwrt"
CONF_SRC="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

# 1. 【物理指纹】
sed -i "s/DISTRIB_DESCRIPTION='.*'/DISTRIB_DESCRIPTION='SL-3000 Exclusive'/g" package/base-files/files/etc/openwrt_release

# 2. 【物理清理】
find package/feeds/packages/ -name "*selinux*" -exec rm -rf {} + || true
rm -rf package/feeds/packages/python-semanage package/system/refpolicy package/system/selinux-policy package/utils/audit package/utils/policycoreutils package/libs/libsemanage package/boot/arm-trusted-firmware-microchipsw || true

# 3. 【DTS 物理注入】从 custom-config 拷贝修复后的 DTS
DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_DIR"
cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$DTS_DIR/mt7981b-3000-emmc.dts"

# 4. 【Makefile 物理追加】
# 注意：确保你的 custom-config/filogic.mk 只包含 Device 定义，以免冲突
cat "${CONF_SRC}/filogic.mk" >> target/linux/mediatek/image/filogic.mk

# 5. 【.config 物理死锁】
cp -fv "${CONF_SRC}/sl3000.config" .config
# 强制追加物理参数防止被 defconfig 剔除
echo "CONFIG_TARGET_mediatek=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
echo "CONFIG_PACKAGE_atf-mt7981=y" >> .config
echo "CONFIG_DEBUG_INFO=n" >> .config
echo "CONFIG_RUST_SUPPORT=n" >> .config
