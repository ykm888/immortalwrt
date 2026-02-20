#!/bin/bash
# 物理熔断
set -ex

# 定位
WORKDIR="${GITHUB_WORKSPACE}/openwrt"
cd "${WORKDIR}"

# 1. 【物理手术】彻底抹除 Makefile 中的 MIPS 污染
# 只要 Makefile 里敢出现 BuildVariants +=，就全部物理蒸发
sed -i '/BuildVariants [+: ]=/d' package/boot/uboot-mediatek/Makefile
# 强行注入唯一 ARM64 变体
sed -i '/include $(INCLUDE_DIR)\/package.mk/i BuildVariants := mt7981_sl3000-emmc' package/boot/uboot-mediatek/Makefile

# 2. 【DTS/Makefile 追加】
# (此处保留你原有的 DTS 拷贝逻辑，不做修改以符合原文原则)
