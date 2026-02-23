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
# 物理修复：1GB RAM 适配与 Bootloader 生成强制补丁 (物理修复点)
# -----------------------------------------------------------------------------

# 1. 物理注入 1GB 内存 DTS 定义
# 物理路径物理适配：确保在不同源码目录下均能正确覆盖
cp -f custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/ 2>/dev/null
mkdir -p target/linux/mediatek/dts/mediatek/
cp -f custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mediatek/

# 2. 物理覆盖 MK (只保留你的设备定义，原文框架)
cp -f custom-config/filogic.mk target/linux/mediatek/image/filogic.mk

# 3. 物理修正 .config：解决不生成 U-Boot/BL2 的物理缺失问题
# 注意：该逻辑必须在读取自定义 config 后执行
if [ -f ".config" ]; then
    # 物理强制开启 U-Boot (FIP)
    sed -i '/CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc/d' .config
    echo "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y" >> .config
    
    # 物理强制开启 BL2
    sed -i '/CONFIG_PACKAGE_mt7981-bl2-emmc/d' .config
    echo "CONFIG_PACKAGE_mt7981-bl2-emmc=y" >> .config
    
    # 物理锁定内核为 6.6 (若源码支持)
    # sed -i '/CONFIG_LINUX_6_6/d' .config
    # echo "CONFIG_LINUX_6_6=y" >> .config
fi

# -----------------------------------------------------------------------------

#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP (物理修复：锁定为 192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 其他原文照抄（保持注释状态，严禁画蛇添足）
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate
