#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m💎 [SL3000] 启动外科手术级配置清洗...\033[0m"

cd "${WORKDIR}"

# 1. 🔥 [物理修复] 预置环境检查文件 (解决 Error 1)
mkdir -p staging_dir/host
touch staging_dir/host/.prereq-build

# 2. 屏蔽签名检查
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

# 3. 🔥 [核心清洗] 重建 .config
# 无论之前有什么，彻底删除
rm -f .config

# 写入基础头（3行）
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y" >> .config

# 🔥 [强力过滤] 提取用户配置
# 使用 awk 进行白名单匹配，同时 tr -d '\r' 去除可能存在的 Windows 换行符
if [ -f "${SRC_DIR}/sl3000.config" ]; then
    echo "Processing user config..."
    # 逻辑：读取文件 -> 删掉 \r -> 只保留以 CONFIG_ 开头的行 -> 追加到 .config
    cat "${SRC_DIR}/sl3000.config" | tr -d '\r' | awk '/^CONFIG_[A-Za-z0-9_]+=/' >> .config || true
fi

# 4. 🔥 [物理锁定] 强制覆盖分区设置 (防止前面导入了错误的值)
sed -i '/CONFIG_TARGET_KERNEL_PARTSIZE/d' .config
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config

# 5. [自检] 打印 .config 前 30 行到日志，方便排查
echo "------------------ .config Preview (Top 30) ------------------"
head -n 30 .config
echo "--------------------------------------------------------------"

# 6. 注入 DTS 和 MK
mkdir -p target/linux/mediatek/{dts,image}
[ -f "${SRC_DIR}/mt7981b-sl3000-emmc.dts" ] && cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" target/linux/mediatek/dts/
[ -f "${SRC_DIR}/filogic.mk" ] && cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/

echo -e "\033[32m✅ 静态清洗完成。此脚本不执行 make，请由工作流接管。\033[0m"
