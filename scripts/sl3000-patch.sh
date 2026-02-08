#!/bin/bash
set -e

# 设置基础路径
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 开始应用最终延续版补丁..."

cd "${WORKDIR}"

# 1. 更新 Feeds 并注入关键配置 [cite: 2026-02-07]
./scripts/feeds update -a && ./scripts/feeds install -a

# 2. ✅ 延续：物理锁定 1GB 设备识别符 [cite: 2026-02-06]
rm -rf tmp .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
} > .config

# 合并用户自定义 config (包含软件包) [cite: 2026-02-07]
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# 3. ✅ 延续：祖传 Bison/M4 路径修复 (2月5日修复项) [cite: 2026-02-05]
mkdir -p staging_dir/host/bin
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done

# 4. ✅ 延续：物理注入资产 (DTS 与 Makefile) [cite: 2026-02-07]
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 5. 预生成配置并锁定 Rootfs 初始大小 [cite: 2026-02-05, 2026-02-06]
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

echo "✅ [SL3000] 脚本补丁执行完毕。"
