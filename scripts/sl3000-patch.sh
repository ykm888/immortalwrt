#!/bin/bash
# 延续所有物理修复设置：SL3000 专属补丁
set -ex

# 定位物理工作空间
WORKDIR="${GITHUB_WORKSPACE}/openwrt"
cd "${WORKDIR}"

# 1. 【物理手术】彻底抹除 Makefile 中的 MIPS 变体污染
# 移除所有 BuildVariants 的追加和定义，防止 aarch64 编译器触发 -mabi=32 错误
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i '/BuildVariants [+: ]=/d' "$UBOOT_MAKEFILE"
    # 强制注入唯一 ARM64 变体定义
    sed -i '/include $(INCLUDE_DIR)\/package.mk/i BuildVariants := mt7981_sl3000-emmc' "$UBOOT_MAKEFILE"
    echo "Physical fix: U-Boot variants locked to mt7981_sl3000-emmc"
fi

# 2. 【DTS 物理覆盖】
# 假设 custom-config 目录下已有对应文件，执行物理替换
CONF_SRC="${GITHUB_WORKSPACE}/custom-config"
DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mediatek"
mkdir -p "$DTS_DIR"
if [ -f "${CONF_SRC}/mt7981b-3000-emmc.dts" ]; then
    cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$DTS_DIR/"
fi

# 3. 【Makefile 物理追加】
# 修正 filogic.mk 以支持 sl3000-emmc 设备定义
if [ -f "${CONF_SRC}/filogic.mk" ]; then
    sed -i '/define Device\/sl3000-emmc/,/endef/d' target/linux/mediatek/image/filogic.mk || true
    cat "${CONF_SRC}/filogic.mk" >> target/linux/mediatek/image/filogic.mk
fi

# 4. 【.config 物理死锁】
# 强制清理冲突项并锁定目标配置
sed -i 's/CONFIG_PACKAGE_uboot-mediatek-.*=y/# CONFIG_PACKAGE_uboot-mediatek- is not set/g' .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000-emmc=y"
    echo "CONFIG_MAKE_FIP_BIN=y"
} >> .config

echo "物理设置已成功延续并锁定。"
