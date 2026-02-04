#!/bin/bash
set -e

ROOT_DIR=$(pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

echo "🔥 [暴力重构] 正在执行硬核物理注入..."

# 1. 强制覆盖官方镜像生成器 (filogic.mk)
# 不管官方原来怎么写，直接用你的 1GB 定义替换
cp -fv "$SRC_DIR/filogic.mk" target/linux/mediatek/image/filogic.mk

# 2. 暴力注册 DTS
# 直接放入 target 模板目录，这样 OpenWrt 每次解压内核都会强制从这里同步
mkdir -p target/linux/mediatek/dts
cp -fv "$SRC_DIR/mt7981b-sl3000-emmc.dts" target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts

# 3. 硬核改写 Makefile 模板 (彻底解决 No such file 报错)
# 我们直接在 target 层的 Makefile 里强制声明 dtb 链接
MTK_DTS_MAKEFILE="target/linux/mediatek/Makefile"
# 如果是 ImmortalWrt，我们将设备名强行塞进内核构建目标
echo "dtb-y += mt7981b-sl3000-emmc.dtb" >> target/linux/mediatek/image/Makefile || true

# 4. 环境劫持 (暴力解决 m4/flex 报错)
mkdir -p staging_dir/host/bin
for tool in m4 flex bison lex; do
    ln -sf /usr/bin/$tool staging_dir/host/bin/$tool
done
touch staging_dir/host/.tools_install_y
mkdir -p staging_dir/host/stamp
touch staging_dir/host/stamp/.tools_compile_y

# 5. 刷新 Feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# 6. 暴力应用配置
cp -fv "$SRC_DIR/sl3000_defconfig" .config
make defconfig

echo "✅ [暴力注入完成] 源码已被彻底篡改。"
#!/bin/bash
set -e

ROOT_DIR=$(pwd)
SRC_DIR="${GITHUB_WORKSPACE}/custom-config"

echo "🔥 [暴力重构] 正在执行硬核物理注入..."

# 1. 强制覆盖官方镜像生成器 (filogic.mk)
# 不管官方原来怎么写，直接用你的 1GB 定义替换
cp -fv "$SRC_DIR/filogic.mk" target/linux/mediatek/image/filogic.mk

# 2. 暴力注册 DTS
# 直接放入 target 模板目录，这样 OpenWrt 每次解压内核都会强制从这里同步
mkdir -p target/linux/mediatek/dts
cp -fv "$SRC_DIR/mt7981b-sl3000-emmc.dts" target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts

# 3. 硬核改写 Makefile 模板 (彻底解决 No such file 报错)
# 我们直接在 target 层的 Makefile 里强制声明 dtb 链接
MTK_DTS_MAKEFILE="target/linux/mediatek/Makefile"
# 如果是 ImmortalWrt，我们将设备名强行塞进内核构建目标
echo "dtb-y += mt7981b-sl3000-emmc.dtb" >> target/linux/mediatek/image/Makefile || true

# 4. 环境劫持 (暴力解决 m4/flex 报错)
mkdir -p staging_dir/host/bin
for tool in m4 flex bison lex; do
    ln -sf /usr/bin/$tool staging_dir/host/bin/$tool
done
touch staging_dir/host/.tools_install_y
mkdir -p staging_dir/host/stamp
touch staging_dir/host/stamp/.tools_compile_y

# 5. 刷新 Feeds
./scripts/feeds update -a && ./scripts/feeds install -a

# 6. 暴力应用配置
cp -fv "$SRC_DIR/sl3000_defconfig" .config
make defconfig

echo "✅ [暴力注入完成] 源码已被彻底篡改。"
