#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 深度修复与资产注入..."

# 0. 严谨性检查：确保 custom-config 存在
if [ ! -d "$SRC_DIR" ]; then
    echo "❌ 错误: 找不到 custom-config 目录，请检查仓库文件！"
    exit 1
fi

cd "${WORKDIR}"

# 1. Feeds 同步 (仅保留一次)
./scripts/feeds update -a && ./scripts/feeds install -a

# 2. 身份配置锁定 (增加内核版本锁定)
rm -rf tmp .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    # 🎯 物理修复：锁定内核版本，解决驱动异常
    echo "CONFIG_LINUX_6_6=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
} > .config

# 3. 核心资产注入 (128MB对齐/1GB内存/DTS)
# 🎯 物理修复：先删再拷，防止符号链接冲突
cat "${SRC_DIR}/sl3000.config" >> .config

mkdir -p "target/linux/mediatek/image"
rm -f "target/linux/mediatek/image/filogic.mk"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

mkdir -p "target/linux/mediatek/dts"
rm -f "target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"

# 4. 环境补丁 (保留原文 Bison 环境补丁逻辑)
# 注意：此时 staging_dir 可能还不完整，真正的软链锁定放在 YAML Step 9
mkdir -p "staging_dir/host/bin"

# 5. 分区锁定
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

echo "✅ [SL3000] 脚本资产注入完成，DTS 已锁定在 target/linux 层。"
