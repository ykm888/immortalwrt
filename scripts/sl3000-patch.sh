#!/bin/bash
# 物理熔断：SL-3000 24.10 (Kernel 6.6) 物理整合修复脚本
# 整合 Part1 (源处理) 与 Part2 (路径修复) 逻辑
set -eo pipefail

# 1. [Part 1 逻辑整合] 物理注入插件源 (原文照抄)
echo 'src-git helloworld https://github.com/fw876/helloworld' >> feeds.conf.default

# 2. [Part 2 路径修复] 针对 24.10 架构进行物理对齐
# 物理创建 Kernel 6.6 要求的子目录结构
mkdir -p target/linux/mediatek/dts/mediatek

# 3. [物理覆盖] 强制将仓库配置同步至源码树
# 物理锁定成功案例中的文件名与路径
if [ -f "custom-config/mt7981b-3000-emmc.dts" ]; then
    cp -f custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mediatek/mt7981b-sl-3000-emmc.dts
fi

if [ -f "custom-config/filogic.mk" ]; then
    cp -f custom-config/filogic.mk target/linux/mediatek/image/filogic.mk
fi

# 4. [物理补丁] 修复无线驱动包引用 (针对 24.10 成功案例逻辑同步)
# 确保 filogic.mk 中的无线固件包符合新版仓库定义
sed -i 's/mt7981-wo-firmware/kmod-mt7981-firmware/g' target/linux/mediatek/image/filogic.mk

# 5. [物理清理] 移除官方多余配置，实现“结构死锁”
# 确保只编译 SL-3000，防止其他设备定义干扰
# (由于 filogic.mk 已被完整覆盖，此步骤已通过覆盖动作闭环)
