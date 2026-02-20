#!/bin/bash
# 物理熔断
set -ex

REPO_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
WORKDIR="${REPO_ROOT}/openwrt"
CONF_SRC="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

# 1. 【物理指纹】
sed -i "s/DISTRIB_DESCRIPTION='.*'/DISTRIB_DESCRIPTION='SL-3000 Exclusive'/g" package/base-files/files/etc/openwrt_release

# 2. 【物理手术：彻底解决架构冲突】
# 修改 uboot-mediatek 的 Makefile，物理删除所有非 sl3000-emmc 的变体定义
# 这样 make 遍历 package 时物理上找不到 mt7620
sed -i '/define uboot-mediatek-/,/$(eval $(call BuildPackage,uboot-mediatek-.*))/ { /sl3000-emmc/!d }' package/boot/uboot-mediatek/Makefile || true

# 3. 【物理清理】
find package/feeds/packages/ -name "*selinux*" -exec rm -rf {} + || true
rm -rf package/feeds/packages/python-semanage package/system/refpolicy package/system/selinux-policy package/utils/audit package/utils/policycoreutils package/libs/libsemanage package/boot/arm-trusted-firmware-microchipsw || true

# 4. 【DTS 物理路径死锁】
DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mediatek"
mkdir -p "$DTS_DIR"
cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$DTS_DIR/mt7981b-3000-emmc.dts"

# 5. 【Makefile 物理追加】
sed -i '/define Device\/sl3000-emmc/,/endef/d' target/linux/mediatek/image/filogic.mk || true
cat "${CONF_SRC}/filogic.mk" >> target/linux/mediatek/image/filogic.mk

# 6. 【.config 物理死锁】
cp -fv "${CONF_SRC}/sl3000.config" .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_PACKAGE_uboot-mediatek=y"
    echo "CONFIG_PACKAGE_atf-mt7981=y"
    echo "CONFIG_UBOOT_mediatek_mt7981_sl3000-emmc=y"
    echo "CONFIG_MAKE_FIP_BIN=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=524288"
    echo "CONFIG_DEBUG_INFO=n"
} >> .config
