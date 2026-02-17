#!/bin/bash
set -eo pipefail

# 严格承袭：原始路径变量结构
REPO_ROOT="${GITHUB_WORKSPACE}"
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m🚀 [SL3000] 执行物理适配 (23.05 身份指纹同步)...\033[0m"

# 1. 资源物理注入 (原文照抄逻辑)
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$WORKDIR/$DTS_DEST"

# 物理同步：注入你的核心 DTS 和镜像生成规则
cp -fv "${SRC_DIR}/mt7981b-3000-emmc.dts" "$WORKDIR/$DTS_DEST/"
cp -fv "${SRC_DIR}/filogic.mk" "$WORKDIR/target/linux/mediatek/image/filogic.mk"

cd "$WORKDIR"

# 2. 【核心修复】：物理对齐 23.05 身份 ID (sl,3000-emmc)
# 这一步解决 U-Boot 校验不通过和 mconf 卡死问题
echo "⚙️ 正在执行物理名称对齐：3000-emmc"

# 强制修正 Makefile：将所有 sl3000 引用对齐为 3000-emmc
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/sl3000/3000-emmc/g' {} + || true
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/SL3000/3000-emmc/g' {} + || true

# 强制修正 DTS 兼容性字符串：确保与 23.05 的 "sl,3000-emmc" 一致
DTS_PATH="$DTS_DEST/mt7981b-3000-emmc.dts"
if [ -f "$DTS_PATH" ]; then
    # 物理覆盖 compatible 和 model 字段
    sed -i 's/compatible = .*/compatible = "sl,3000-emmc", "mediatek,mt7981";/' "$DTS_PATH"
    sed -i 's/model = .*/model = "SL-3000 eMMC bootstrap version";/' "$DTS_PATH"
fi

# 3. 物理修复：一次性锁定 128MB 偏移并强制产出 U-Boot
# 严格按照用户原则：不准漏掉任何之前验证过的补丁
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    # 物理锁定：设备 ID 必须是 3000-emmc
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_3000-emmc=y"
    # 物理锁定：确保 U-Boot 被选中
    echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    echo "CONFIG_TARGET_IMAGE_uboot-mediatek-mt7981_sl-3000-emmc=y"
    # 物理锁定：128MB 分区偏移 (131072 KB)
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=131072"
    echo "CONFIG_TARGET_ROOTFS_PARTNAME=\"rootfs\""
    # 物理锁定：补全 eMMC 识别驱动与分区工具
    echo "CONFIG_PACKAGE_kmod-mtk-sd=y"
    echo "CONFIG_PACKAGE_kmod-gpt=y"
    echo "CONFIG_PACKAGE_kmod-part-msdos=y"
    echo "CONFIG_PACKAGE_luci=y"
} >> .config

# 4. 生成物理锁定的备份配置，用于 Workflow 的二次强灌
cp -fv .config .config.locked

# 5. 物理刷新 DTS 时间戳，彻底终结 mconf 循环扫描
find target/linux/mediatek/files-6.6/ -name "*.dts*" -exec touch {} + || true

echo "✅ 补丁脚本执行完毕，已完成身份物理重写与配置锁定。"
