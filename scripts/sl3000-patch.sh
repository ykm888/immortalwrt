#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 启动架构锁定与 1GB/eMMC 注入修复..."

cd "${WORKDIR}"

# 1. 物理清理：彻底抹除所有可能导致跳回 x86 的缓存配置
rm -rf tmp
rm -f .config .config.old

# 2. 更新 Feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# 3. 核心修复：强制注入目标架构（防止系统自作主张选择 x86）
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# 4. 载入您的自定义 defconfig (延续之前的内存/分区设置)
if [ -f "${SRC_DIR}/sl3000_defconfig" ]; then
    cat "${SRC_DIR}/sl3000_defconfig" >> .config
fi

# 5. 注入设备定义 (MK) 与 DTS
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

mkdir -p "custom_files"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "custom_files/"

# 6. 劫持 Host 工具防止冲突 (延续之前的 fix)
mkdir -p "staging_dir/host/bin"
for tool in m4 flex bison lex; do
    rm -f "staging_dir/host/bin/$tool"
    ln -sf "/usr/bin/$tool" "staging_dir/host/bin/$tool"
done
touch "staging_dir/host/.tools_install_y"

# 7. 生成完整配置并校验
make defconfig

# 8. 架构双重校验：如果此时还是 x86，直接熔断报错
if grep -q "CONFIG_TARGET_x86=y" .config; then
    echo "❌ 严重错误：架构锁定失败，检测到 x86 污染！"
    exit 1
fi

echo "✅ 注入完成，架构已锁定为 MediaTek Filogic。"
