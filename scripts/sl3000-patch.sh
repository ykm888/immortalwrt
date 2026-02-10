#!/bin/bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo "💎 [SL3000] 执行物理补丁全量归位：严格执行原文照抄原则..."

cd "${WORKDIR}"

# ============================================================
# [阶段1] 基础环境准备
# ============================================================
echo "📦 [1/8] 创建基础目录结构..."
mkdir -p staging_dir/host/bin staging_dir/host/share
mkdir -p target/linux/mediatek/dts target/linux/mediatek/image

# ============================================================
# [阶段2] 屏蔽编译警告 (防止 -Werror 导致构建失败)
# ============================================================
echo "🛡️ [2/8] 屏蔽所有 Makefile 中的 -Werror..."
find . -name Makefile -type f -exec sed -i 's/ERROR_ON_WARNING = y/ERROR_ON_WARNING = n/g' {} +
find . -name "Makefile.dtc" -type f -exec sed -i 's/-Werror//g' {} + || true

# ============================================================
# [阶段3] 配置文件注入 (在 feeds 更新前)
# ============================================================
echo "⚙️ [3/8] 注入基础配置..."
rm -f .config

cat > .config << 'EOF'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y
CONFIG_TARGET_KERNEL_PARTSIZE=128
CONFIG_TARGET_ROOTFS_PARTSIZE=1024
EOF

# 合并用户配置
if [ -f "${SRC_DIR}/sl3000.config" ]; then
    echo "📄 合并用户配置文件..."
    cat "${SRC_DIR}/sl3000.config" >> .config
fi

# 生成完整配置
make defconfig

# ============================================================
# [阶段4] Feeds 管理
# ============================================================
echo "📡 [4/8] 更新和安装 feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# ============================================================
# [阶段5] 🔥 关键修复：构建 host tools (包含 usign)
# ============================================================
echo "🔨 [5/8] 构建 host tools (包含 usign)..."

# 设置环境变量
export BISON_PKGDATADIR=$(pkg-config --variable=pkgdatadir bison 2>/dev/null || echo '/usr/share/bison')
export M4=$(which m4)

# 先尝试完整构建 tools
if ! make tools/install -j$(nproc) V=s; then
    echo "⚠️ 并行构建失败，尝试单线程构建..."
    make tools/install -j1 V=s
fi

# 🔥 核心修复：确保 usign 被构建
if [ ! -f "staging_dir/host/bin/usign" ]; then
    echo "❌ usign 未找到，强制构建..."
    make tools/usign/clean V=s || true
    make tools/usign/compile V=s
    make tools/usign/install V=s
fi

# 验证 usign
if [ ! -f "staging_dir/host/bin/usign" ]; then
    echo "💥 错误：usign 构建失败！"
    exit 1
fi
echo "✅ usign 已就绪: $(readlink -f staging_dir/host/bin/usign)"

# ============================================================
# [阶段6] 可选：创建系统工具软链接 (避免重复构建)
# ============================================================
echo "🔗 [6/8] 创建系统工具软链接..."
for tool in m4 flex bison gawk sed patch tar xz gzip bzip2 perl python3 wget curl; do
    if [ -f "staging_dir/host/bin/$tool" ]; then
        echo "  ⏭️  $tool 已存在，跳过"
    else
        TOOL_PATH=$(which $tool 2>/dev/null || true)
        if [ -n "$TOOL_PATH" ]; then
            ln -sf "$TOOL_PATH" "staging_dir/host/bin/$tool"
            echo "  ✓ 链接 $tool"
        fi
    fi
done

# Bison 数据目录
if [ -d "$BISON_PKGDATADIR" ]; then
    ln -sf "$BISON_PKGDATADIR" "staging_dir/host/share/bison" 2>/dev/null || true
fi

# ============================================================
# [阶段7] DTS 与 Image 配置注入
# ============================================================
echo "📝 [7/8] 注入 DTS 和 Image 配置..."

if [ -f "${SRC_DIR}/mt7981b-sl3000-emmc.dts" ]; then
    cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "target/linux/mediatek/dts/"
    echo "✅ DTS 文件已注入"
else
    echo "⚠️ 警告：DTS 文件不存在 - ${SRC_DIR}/mt7981b-sl3000-emmc.dts"
fi

if [ -f "${SRC_DIR}/filogic.mk" ]; then
    cp -fv "${SRC_DIR}/filogic.mk" "target/linux/mediatek/image/filogic.mk"
    echo "✅ Image Makefile 已注入"
else
    echo "⚠️ 警告：filogic.mk 文件不存在 - ${SRC_DIR}/filogic.mk"
fi

# ============================================================
# [阶段8] 最终配置锁定
# ============================================================
echo "🔒 [8/8] 最终配置验证..."

# 确保关键配置已设置
grep -q "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" .config || \
    sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/' .config

grep -q "CONFIG_TARGET_KERNEL_PARTSIZE=128" .config || \
    sed -i 's/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=128/' .config

# 再次运行 defconfig 确保一致性
make defconfig

# ============================================================
# 完成报告
# ============================================================
echo ""
echo "✅ ============================================"
echo "✅ SL3000 补丁脚本执行完成！"
echo "✅ ============================================"
echo ""
echo "📊 关键路径验证："
echo "  - usign: $([ -f staging_dir/host/bin/usign ] && echo '✅' || echo '❌')"
echo "  - DTS: $([ -f target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts ] && echo '✅' || echo '❌')"
echo "  - Image config: $([ -f target/linux/mediatek/image/filogic.mk ] && echo '✅' || echo '❌')"
echo ""
echo "🚀 下一步："
echo "  1. make toolchain/install -j\$(nproc) V=s"
echo "  2. make target/linux/compile -j\$(nproc) V=s"
echo "  3. make package/compile -j\$(nproc) V=s"
echo "  4. make package/index V=s"
echo "  5. make package/install V=s"
echo "  6. make target/install V=s"
echo ""
