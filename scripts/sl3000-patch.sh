#!/bin/bash
# 物理熔断
set -ex

# 物理死锁：锚定路径变量
REPO_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
WORKDIR="${REPO_ROOT}/openwrt"
CONF_SRC="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

# 1. 【专属指纹】
cat << 'EOF' > package/base-files/files/etc/banner
  _______                     ________        
 |       |.-----.-----.-----.|  |  |  |.----. _|_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||  _|
 |_______||   __|_____|__|__||________||__|  |___|
          |__| SL-3000 EXCLUSIVE SOURCE
 -----------------------------------------------------
  BUILD: $(date +%Y-%m-%d) | OWNER: SL-3000 PRIVATE
 -----------------------------------------------------
EOF

sed -i "s/DISTRIB_DESCRIPTION='.*'/DISTRIB_DESCRIPTION='SL-3000 Exclusive'/g" package/base-files/files/etc/openwrt_release

# 2. 【彻底铲平】物理抹除所有 SELinux 相关的“钉子户”
# 移除所有依赖 libsemanage, libaudit, policycoreutils 的包
find package/feeds/packages/ -name "*selinux*" -exec rm -rf {} + || true
find package/feeds/packages/ -name "*policycoreutils*" -exec rm -rf {} + || true
find package/feeds/packages/ -name "*libsemanage*" -exec rm -rf {} + || true
find package/feeds/packages/ -name "*libaudit*" -exec rm -rf {} + || true
rm -rf package/feeds/packages/python-semanage || true
rm -rf package/system/refpolicy || true
rm -rf package/system/selinux-policy || true
rm -rf package/utils/audit || true
rm -rf package/utils/policycoreutils || true
rm -rf package/libs/libsemanage || true
rm -rf package/boot/arm-trusted-firmware-microchipsw || true

# 3. 【三件套物理注入】
rm -f .config*
if [ -f "${CONF_SRC}/sl3000.config" ]; then
    cp -fv "${CONF_SRC}/sl3000.config" .config
    # 物理过滤：防止 config 文件内残留的变量再次激活这些包
    sed -i '/SELINUX/d' .config
    sed -i '/policycoreutils/d' .config
    sed -i '/libsemanage/d' .config
    sed -i '/libaudit/d' .config
    
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config
    echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
    echo "CONFIG_PACKAGE_atf-mt7981=y" >> .config
fi

DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_DIR"
[ -f "${CONF_SRC}/mt7981b-3000-emmc.dts" ] && cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$DTS_DIR/"
[ -f "${CONF_SRC}/filogic.mk" ] && cp -fv "${CONF_SRC}/filogic.mk" "target/linux/mediatek/image/filogic.mk"
