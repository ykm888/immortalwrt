#!/bin/bash
# 物理熔断：彻底解决架构交叉污染
set -ex

# 1. 定位物理路径（严格承袭原文逻辑）
REPO_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
WORKDIR="${REPO_ROOT}/openwrt"
CONF_SRC="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

# 2. 【核心修复：物理手术截断】
# 报错根源：Makefile 中残留的 MIPS 变体会被 aarch64 编译器扫描。
# 物理操作：直接从 Makefile 中物理删除所有旧的变体追加行。
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 物理清空所有 BuildVariants 定义，杜绝 mt7620 等 MIPS 型号干扰
    sed -i '/BuildVariants [+: ]=/d' "$UBOOT_MAKEFILE"
    # 物理注入：强行硬编码唯一的 ARM64 变体，使用 := 锁定
    sed -i '/include $(INCLUDE_DIR)\/package.mk/i BuildVariants := mt7981_sl3000-emmc' "$UBOOT_MAKEFILE"
    echo "物理隔离：已锁定唯一变体 mt7981_sl3000-emmc"
fi

# 3. 【DTS 物理对齐】
DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mediatek"
mkdir -p "$DTS_DIR"
[ -f "${CONF_SRC}/mt7981b-3000-emmc.dts" ] && cp -fv "${CONF_SRC}/mt7981b-3000-emmc.dts" "$DTS_DIR/"

# 4. 【Makefile 物理追加】
# 物理删除旧定义并追加你的 filogic.mk 逻辑
sed -i '/define Device\/sl3000-emmc/,/endef/d' target/linux/mediatek/image/filogic.mk || true
[ -f "${CONF_SRC}/filogic.mk" ] && cat "${CONF_SRC}/filogic.mk" >> target/linux/mediatek/image/filogic.mk

# 5. 【.config 物理锁死】
# 强制清理可能冲突的 U-Boot 选项，并注入正确配置
sed -i 's/CONFIG_PACKAGE_uboot-mediatek-.*=y/# CONFIG_PACKAGE_uboot-mediatek- is not set/g' .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000-emmc=y"
    echo "CONFIG_MAKE_FIP_BIN=y"
} >> .config
