#!/bin/bash
set -e

# 校准根路径：严格防止双重路径拼接 [cite: 2026-02-08]
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 应用终极版补丁 (保留所有历史修复)..."

cd "${WORKDIR}"
./scripts/feeds update -a && ./scripts/feeds install -a

# 1. 延续设置：物理锁定 1GB RAM 设备逻辑 [cite: 2026-02-06]
rm -rf tmp .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    # ✅ 修正：锁定 128MB 内核分区配置
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
} > .config
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# 2. 延续设置：祖传 Bison 路径补丁 [cite: 2026-02-05]
mkdir -p staging_dir/host/bin
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done

# 3. 物理修复：将 DTS 放入预备目录 (供工作流第 8 步精准捞取)
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"

# 4. 核心补丁：物理强制修改 filogic.mk [cite: 2026-02-09]
# 不再直接覆盖，而是向现有的 Makefile 追加我们的设备定义，防止丢失官方驱动
FILOGIC_MK="target/linux/mediatek/image/filogic.mk"
if [ -f "${SRC_DIR}/filogic.mk" ]; then
    echo "💉 注入 SL3000 设备定义到 $FILOGIC_MK"
    cat "${SRC_DIR}/filogic.mk" >> "$FILOGIC_MK"
fi

# 5. 锁定分区大小 [cite: 2026-02-07]
make defconfig
# 确保 rootfs 至少有 1GB 空间定义
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config

echo "✅ [SL3000] 补丁完成。历史修复已全部携带。"
