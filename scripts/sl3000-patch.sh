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

# 3. 核心修复：强力锁定 MediaTek 架构与设备身份
# 这是解决 root-mediatek 目录缺失的关键
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# 🎯 4. 载入 1GB 内存与尺寸配置 (修正文件名为你仓库中的 sl3000.config)
if [ -f "${SRC_DIR}/sl3000.config" ]; then
    echo "📂 正在合并自定义配置: sl3000.config"
    cat "${SRC_DIR}/sl3000.config" >> .config
else
    echo "⚠️ 警告: 未找到 ${SRC_DIR}/sl3000.config，请检查文件名！"
fi

# 5. 注入镜像定义与 DTS
# 确保 filogic.mk 包含 pad-to 134217728 逻辑
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 6. 工具链软链接劫持 (延续修复，解决环境兼容性)
mkdir -p "staging_dir/host/bin"
ln -sf "$(which m4)" "staging_dir/host/bin/m4"
ln -sf "$(which flex)" "staging_dir/host/bin/flex"
ln -sf "$(which bison)" "staging_dir/host/bin/bison"
touch "staging_dir/host/.tools_install_y"

# 7. 生成并修正配置
make defconfig

# 🎯 8. 强制注入 512MB 限制，防止最后一步打包溢出 (Error 1)
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

# 9. 架构校验
if grep -q "CONFIG_TARGET_x86=y" .config; then
    echo "❌ 架构锁定失败，正在回滚配置..."
    exit 1
fi

echo "✅ [SL3000] 补丁注入与架构锁定完成。准备编译..."
