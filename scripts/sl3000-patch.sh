#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 启动 V13.5 补丁注入 (全量修复延续版)..."

cd "${WORKDIR}"

# 1. 清理环境，防止旧配置污染
rm -rf tmp .config .config.old

# 2. 更新 Feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# 3. 核心修复：强力锁定 MediaTek 架构
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# 4. 载入 1GB 内存与 128M 内核分区配置
if [ -f "${SRC_DIR}/sl3000_defconfig" ]; then
    cat "${SRC_DIR}/sl3000_defconfig" >> .config
fi

# 5. 注入设备镜像定义 (包含最新的 128MB 修正)
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 6. Host 工具路径劫持 (解决 bison/m4/flex 报错)
mkdir -p "staging_dir/host/bin"
ln -sf "/usr/bin/m4" "staging_dir/host/bin/m4"
ln -sf "/usr/bin/flex" "staging_dir/host/bin/flex"
ln -sf "/usr/bin/bison" "staging_dir/host/bin/bison"
touch "staging_dir/host/.tools_install_y"

# 7. 生成最终配置
make defconfig

# 8. 架构校验
if grep -q "CONFIG_TARGET_x86=y" .config; then
    echo "❌ 架构锁定失败！" && exit 1
fi

echo "✅ 补丁注入与架构锁定完成。"
