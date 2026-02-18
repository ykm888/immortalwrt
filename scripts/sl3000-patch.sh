#!/bin/bash
# 物理熔断
set -ex

# 物理死锁：锚定路径变量
REPO_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
WORKDIR="${REPO_ROOT}/openwrt"
CONF_SRC="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

# 1. 【专属指纹】物理修改系统标识
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

# 2. 【彻底铲平】物理移除所有可能导致依赖断裂的 SELinux 工具及库
# 强制移除 package 目录下的残余
rm -rf package/feeds/packages/selinux-python || true
rm -rf package/feeds/packages/policycoreutils || true
rm -rf package/feeds/packages/libsemanage || true
rm -rf package/feeds/packages/libaudit || true
# 强制移除 feeds 映射目录（根治 WARNING）
rm -rf feeds/packages/utils/policycoreutils || true
rm -rf feeds/packages/libs/libsemanage || true
rm -rf feeds/packages/libs/libaudit || true
rm -rf package/utils/policycoreutils || true
rm -rf package/libs/libsemanage || true
rm -rf package/boot/arm-trusted-firmware-microchipsw || true

# 3. 【三件套物理注入】
# 物理重置：彻底清除旧配置缓存
rm -f .config*
if [ -f "${CONF_SRC}/sl3000.config" ]; then
    cp -fv "${CONF_SRC}/sl3000.config" .config
    # 物理过滤：防止 config 文件内残留的 policycoreutils 导致编译拉取
    sed -i '/policycoreutils/d' .config
    sed -i '/libsemanage/d' .config
    sed -i '/libaudit/d' .config
    
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config
    echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
    echo "CONFIG_PACKAGE_atf-mt7981=y" >> .config
fi

DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_DIR"
if [ -f "${CONF_SRC}/mt7981b-3000-emmc.dts" ]; then
    cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$DTS_DIR/"
fi

if [ -f "${CONF_SRC}/filogic.mk" ]; then
    cp -fv "${CONF_SRC}/filogic.mk" "target/linux/mediatek/image/filogic.mk"
fi

# 4. 【物理自愈】
if [ -d "build_dir" ]; then
    find build_dir/ -type d -path "*/arch/arm64/boot/dts/mediatek" | while read -r d; do
        cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$d/"
    done
fi
