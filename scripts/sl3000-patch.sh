#!/bin/bash
set -e

echo "🛠️  正在执行 SL3000 专属源码物理修改..."

# 1. 彻底解决 m4/flex 宿主机报错
mkdir -p staging_dir/host/bin
ln -sf /usr/bin/m4 staging_dir/host/bin/m4
ln -sf /usr/bin/flex staging_dir/host/bin/flex
ln -sf /usr/bin/bison staging_dir/host/bin/bison
touch staging_dir/host/.tools_install_y

# 2. 注入 1GB 扩容配置到 .config
cp ../custom-config/sl3000_defconfig .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=1024" >> .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config

# 3. 物理覆盖官方镜像规则
if [ -f "../custom-config/filogic.mk" ]; then
    cp -fv ../custom-config/filogic.mk target/linux/mediatek/image/filogic.mk
fi

# 4. 更新插件源
./scripts/feeds update -a && ./scripts/feeds install -a
make defconfig

echo "✅ 专属源码修改完成！"
