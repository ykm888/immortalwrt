#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#

# Add a feed source (原文照抄)
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# -----------------------------------------------------------------------------
# 物理修复：三件套注入与 U-Boot 生成设置 (物理修复点)
# -----------------------------------------------------------------------------

# 1. 物理注入 DTS (确保 1GB RAM 定义生效)
# 同时兼容 24.10 的两个可能路径
cp -f custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/dts/mediatek/
cp -f custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mediatek/

# 2. 物理覆盖 MK (确保删除其他设备，只保留 SL-3000 并启用构建逻辑)
cp -f custom-config/filogic.mk target/linux/mediatek/image/filogic.mk

# 3. 物理校准 .config (强制开启 U-Boot 生成开关)
if [ -f "openwrt/.config" ]; then
    # 物理锁定 U-Boot 包编译，确保生成 fip.bin
    sed -i '/CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc/d' openwrt/.config
    echo "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y" >> openwrt/.config
    
    # 物理锁定内核 6.6
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

# 修改 IP 或主题的占位符 (原文照抄)
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate
