#!/bin/bash
set -e

# 设置基础路径
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 正在应用最终延续版补丁 (含祖传修复)..."

cd "${WORKDIR}"

# 1. 更新并安装 Feeds (保持环境最新)
./scripts/feeds update -a && ./scripts/feeds install -a

# 2. 核心配置锁定 (延续祖传 1GB RAM / 128MB 分区配置)
rm -rf tmp .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
} > .config

# 注入自定义 config (包含你选中的软件包)
if [ -f "${SRC_DIR}/sl3000.config" ]; then
    cat "${SRC_DIR}/sl3000.config" >> .config
fi

# 3. 祖传补丁：Bison/M4 工具链路径加固 (防止编译 host 工具报错)
# 即使缓存恢复了，重新建立软链接也是秒级操作，确保环境不出错
mkdir -p staging_dir/host/bin
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done

# 4. 资产物理注入 (DTS 与 镜像生成 Makefile)
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 5. 延续修复：锁定 Rootfs 初始大小，防止分区溢出
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

echo "✅ [SL3000] 脚本补丁应用完成，祖传配置已全部就位。"
