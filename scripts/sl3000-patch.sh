#!/bin/bash
set -eo pipefail

# 严格承袭：原始路径变量结构
REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行物理适配 (全量补丁注入与全自动名称校准)...\033[0m"

# 1. 资源物理注入 (原文照抄逻辑)
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$WORKDIR/$DTS_DEST"

# 物理同步：注入你的核心 DTS 和镜像生成规则
cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$WORKDIR/$DTS_DEST/"
cp -fv "${SRC_DIR}/filogic.mk" "$WORKDIR/target/linux/mediatek/image/filogic.mk"

cd "$WORKDIR"

# 2. 【核心修复】：全自动名称匹配逻辑
# 强制将源码中所有的 mt7981-sl3000 逻辑物理重定向到你的 3000-emmc
echo "⚙️ 正在执行物理名称对齐：3000-emmc"
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/sl3000/3000-emmc/g' {} + || true
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/SL3000/3000-emmc/g' {} + || true
find target/linux/mediatek/files-6.6/ -name "*.dts*" -exec sed -i 's/sl3000/3000-emmc/g' {} + || true

# 3. 物理修复：一次性锁定 128MB 偏移并强制产出 U-Boot
# 严格按照用户原则：原文照抄逻辑，不准漏掉任何之前验证过的补丁
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_3000-emmc=y"
    # 物理锁定：确保 U-Boot 被选中（解决不生成 u-boot 的问题）
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    echo "CONFIG_TARGET_IMAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    # 物理锁定：修复 128MB 分区偏移报错
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTNAME=\"rootfs\""
    # 物理锁定：补全 eMMC 识别驱动与分区工具
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y"
    echo "CONFIG_PACKAGE_kmod-gpt=y"
    echo "CONFIG_PACKAGE_kmod-part-msdos=y"
    echo "CONFIG_PACKAGE_luci=y"
} >> .config

# 4. 物理生成锁定的备份配置，用于 Workflow 的二次强灌（防止被 oldconfig 篡改）
cp -fv .config .config.locked

echo "✅ 补丁脚本执行完毕，已完成全量名称校准与配置锁定。"
