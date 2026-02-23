#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Add a feed source (原文照抄)
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# -----------------------------------------------------------------------------
# 物理修复：三件套注入与硬件定义 (物理修复点)
# -----------------------------------------------------------------------------

# 1. 物理注入 DTS (确保 1GB RAM 原文逻辑生效)
# 适配 24.10 物理路径
cp -f custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/dts/mediatek/
cp -f custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mediatek/

# 2. 物理覆盖 MK (只保留 SL-3000 设备，原文结构框架)
cp -f custom-config/filogic.mk target/linux/mediatek/image/filogic.mk

# 3. 物理校准 .config (强制生成 U-Boot 与内核锁定)
if [ -f "openwrt/.config" ]; then
    # 强制开启 U-Boot 编译，确保生成 fip.bin
    sed -i '/CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc/d' openwrt/.config
    echo "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y" >> openwrt/.config
    
    # 锁定内核版本 6.6
    sed -i '/CONFIG_LINUX_6_6/d' openwrt/.config
    echo "CONFIG_LINUX_6_6=y" >> openwrt/.config
fi

# -----------------------------------------------------------------------------

#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP (物理修复：锁定为 192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate
