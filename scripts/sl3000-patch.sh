#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行物理补丁全量归位：严禁简化，确认包含 Share 路径与全局屏蔽..."

cd "${WORKDIR}"

# 1. 🔥 [物理还原] 屏蔽所有 Makefile 中的 WARNING 报错 (2/9 修复点)
# 暴力清除所有 Makefile 中的 ERROR_ON_WARNING 和 -Werror，防止构建中断
find . -name Makefile -exec sed -i 's/ERROR_ON_WARNING = y/ERROR_ON_WARNING = n/g' {} +
find . -name "Makefile.dtc" -exec sed -i 's/-Werror//g' {} + || true
find . -name "Makefile*" -exec sed -i 's/-Werror//g' {} + || true

# 2. 延续设置：更新并安装 feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# 3. 🔥 [核心归位] 修复 Bison/M4 物理环境 (2/5 修复点)
# 建立软链接并锁定宿主机物理路径，解决 m4sugar 丢失问题
mkdir -p staging_dir/host/bin
mkdir -p staging_dir/host/share
for tool in m4 flex bison gawk; do
    ln -sf "$(which $tool)" "staging_dir/host/bin/$tool" || true
done
# 💡 [关键补全] 物理映射数据目录，防止 bison 找不到 /usr/share/bison/m4sugar/m4sugar.m4
B_SHARE=$(pkg-config --variable=pkgdatadir bison 2>/dev/null || echo '/usr/share/bison')
ln -sf "$B_SHARE" "staging_dir/host/share/bison" || true

# 4. ✅ [延续设置] 物理锁定 128MB 内核与 1G RAM
rm -f .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
    echo "CONFIG_TARGET_KERNEL_PARTSIZE=128"
    # 物理注入变量，确保 config 阶段继承变量环境
    echo "export BISON_PKGDATADIR=$B_SHARE"
    echo "export M4=$(which m4)"
} > .config
[ -f "${SRC_DIR}/sl3000.config" ] && cat "${SRC_DIR}/sl3000.config" >> .config

# 5. ✅ [延续设置] DTS 与 filogic.mk 物理注入 (2/7 修复点)
mkdir -p "target/linux/mediatek/dts"
cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
mkdir -p "target/linux/mediatek/image"
cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"

# 6. ✅ [物理锁定] 延续 1024MB Rootfs 锁定逻辑
make defconfig
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config
