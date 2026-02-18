#!/bin/bash
# 物理熔断
set -ex

# 物理死锁：锚定路径变量
REPO_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
WORKDIR="${REPO_ROOT}/openwrt"
CONF_SRC="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

# 1. 【专属指纹】物理修改系统 Banner (SSH 登录界面)
cat << 'EOF' > package/base-files/files/etc/banner
  _______                     ________        
 |       |.-----.-----.-----.|  |  |  |.----. _|_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||  _|
 |_______||   __|_____|__|__||________||__|  |___|
          |__| SL-3000 EXCLUSIVE SOURCE
 -----------------------------------------------------
  BUILD: $(date +%Y-%m-%d) | BRANCH: 24.10
  OWNER: SL-3000 PRIVATE EDITION
 -----------------------------------------------------
EOF

# 2. 【专属指纹】物理修改系统版本描述与 Luci 底部标识
sed -i "s/DISTRIB_DESCRIPTION='.*'/DISTRIB_DESCRIPTION='SL-3000 Exclusive Source'/g" package/base-files/files/etc/openwrt_release
# 物理修改 Luci 底部版权 (强制注入)
sed -i "s/Powered by .*$/Powered by SL-3000 Exclusive Source/g" package/feeds/luci/luci-base/po/zh_Hans/base.po || true
sed -i "s/Powered by .*$/Powered by SL-3000 Exclusive Source/g" package/feeds/luci/luci-base/root/usr/share/rpcd/acl.d/luci-base.json || true

# 3. 【体系延续】物理铲平所有 SELinux/Audit 连带冲突 (防止构建卡死)
rm -rf package/libs/libsemanage || true
rm -rf package/feeds/packages/python-semanage || true
rm -rf package/feeds/packages/selinux-python || true
rm -rf package/utils/audit || true
rm -rf package/utils/policycoreutils || true
rm -rf package/system/refpolicy || true
rm -rf package/system/selinux-policy || true
rm -rf package/boot/arm-trusted-firmware-microchipsw || true

# 4. 【三件套物理注入】
[ -f "${CONF_SRC}/sl3000.config" ] && cp -fv "${CONF_SRC}/sl3000.config" .config
# 物理补全包名死锁
echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
echo "CONFIG_PACKAGE_atf-mt7981=y" >> .config

# DTS 注入 (物理锁定内核 6.6 路径)
DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_DIR"
[ -f "${CONF_SRC}/mt7981b-3000-emmc.dts" ] && cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$DTS_DIR/"

# Makefile 注入
[ -f "${CONF_SRC}/filogic.mk" ] && cp -fv "${CONF_SRC}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 5. 【物理自愈】强灌 build_dir (确保交叉编译中途 DTS 不被官方库覆盖)
if [ -d "build_dir" ]; then
    find build_dir/ -type d -path "*/arch/arm64/boot/dts/mediatek" | while read -r d; do
        cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$d/"
    done
fi
