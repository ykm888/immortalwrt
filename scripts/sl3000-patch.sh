#!/bin/bash
# 物理熔断：SL3000 24.10 物理隔离绝杀版
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

# 1. [源头封锁]
rm -rf feeds.conf
printf 'src-git packages https://github.com/immortalwrt/packages.git\n' > feeds.conf.default
printf 'src-git luci https://github.com/immortalwrt/luci.git\n' >> feeds.conf.default

# 2. [物理对齐]
./scripts/feeds update -a
./scripts/feeds install -a -f

# 3. [物理源码锁定]
mkdir -p dl
wget -t 5 -T 20 "https://github.com/u-boot/u-boot/archive/refs/tags/v2024.10.tar.gz" -O "dl/u-boot-2024.10.tar.gz"

# 4. 🔥 [物理绝杀：Makefile 内部路径硬隔离]
UB_DIR="package/boot/uboot-mediatek"
mkdir -p "$UB_DIR/files"
rm -rf "$UB_DIR/patches"

if [ -f "${SRC_DIR}/mt7981b-3000-emmc.dts" ]; then
    cp -v "${SRC_DIR}/mt7981b-3000-emmc.dts" "$UB_DIR/files/sl3000.dts"
fi

cat << 'EOF' > "$UB_DIR/Makefile"
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_VERSION:=2024.10
PKG_RELEASE:=1
PKG_SOURCE:=u-boot-$(PKG_VERSION).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/u-boot-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/uboot-mediatek-mt7981-sl3000-emmc
  SECTION:=boot
  CATEGORY:=Boot Loader
  TITLE:=U-Boot for SL3000 (Isolate Physical Fix)
  DEPENDS:=@TARGET_mediatek
endef

define Build/Prepare
	$(Build/Prepare/Default)
	echo "#define CFG_SYS_INIT_RAM_ADDR 0x40000000" >> $(PKG_BUILD_DIR)/include/configs/mt7981.h
	echo "#define CFG_SYS_INIT_RAM_SIZE 0x00040000" >> $(PKG_BUILD_DIR)/include/configs/mt7981.h
	echo "#define CFG_SYS_INIT_SP_ADDR (CFG_SYS_INIT_RAM_ADDR + CFG_SYS_INIT_RAM_SIZE - 0x10)" >> $(PKG_BUILD_DIR)/include/configs/mt7981.h
	cp ./files/sl3000.dts $(PKG_BUILD_DIR)/arch/arm/dts/mt7981-sl3000-emmc.dts
	sed -i '/dtb-$$(CONFIG_ARCH_MEDIATEK) +=/ s/$$/ mt7981-sl3000-emmc.dtb/' $(PKG_BUILD_DIR)/arch/arm/dts/Makefile
	cp $(PKG_BUILD_DIR)/configs/mt7981_emmc_rfb_defconfig $(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig
	sed -i 's/DEFAULT_DEVICE_TREE=.*/DEFAULT_DEVICE_TREE="mt7981-sl3000-emmc"/' $(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig
	echo "CONFIG_TEXT_BASE=0x41e00000" >> $(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) mt7981_sl3000_emmc_defconfig
	$(MAKE) -C $(PKG_BUILD_DIR) CROSS_COMPILE=$(TARGET_CROSS) DEVICE_DTS=mt7981-sl3000-emmc
endef

define Package/uboot-mediatek-mt7981-sl3000-emmc/install
	$(INSTALL_DIR) $(1)
	$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(1)/u-boot-sl3000.bin
endef

$(eval $(call BuildPackage,uboot-mediatek-mt7981-sl3000-emmc))
EOF

# 5. [配置锁定]
touch .config
if [ -f "${SRC_DIR}/sl3000.config" ]; then
    cp -fv "${SRC_DIR}/sl3000.config" .config
else
    cat <<EOF > .config
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_3000-emmc=y
CONFIG_PACKAGE_uboot-mediatek-mt7981-sl3000-emmc=y
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
EOF
fi

# 6. [内核 DTS 物理注入]
if [ -f "${SRC_DIR}/mt7981b-3000-emmc.dts" ]; then
    find target/linux/mediatek/ -name "dts" -type d | while read -r dts_dir; do
        mkdir -p "$dts_dir/mediatek"
        cp -v "${SRC_DIR}/mt7981b-3000-emmc.dts" "$dts_dir/mediatek/"
    done
fi

# 7. [filogic.mk 物理追加]
if [ -f "${SRC_DIR}/filogic.mk" ]; then
    MK_FILE="target/linux/mediatek/image/filogic.mk"
    sed -i '/define Device\/sl3000-emmc/,/endef/d' "$MK_FILE" || true
    cat "${SRC_DIR}/filogic.mk" >> "$MK_FILE"
fi
