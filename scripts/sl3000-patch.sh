#!/bin/bash
# 物理熔断：SL3000 24.10 字符转义与补丁隔离版
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

cd "${WORKDIR}"

# 1. [物理清场]
./scripts/feeds update -a
./scripts/feeds install -a -f
rm -rf build_dir/target-aarch64_cortex-a53_musl/u-boot-2024.10
rm -rf build_dir/target-aarch64_cortex-a53_musl/arm-trusted-firmware-mediatek*

# 2. [源码物理装载]
mkdir -p dl
if [ ! -f "dl/u-boot-2024.10.tar.gz" ]; then
    curl -L "https://github.com/u-boot/u-boot/archive/refs/tags/v2024.10.tar.gz" -o dl/u-boot-2024.10.tar.gz
fi

# 3. 🔥 [U-Boot 物理绝杀：移除旧补丁 + 修正 SED 转义]
UB_DIR="package/boot/uboot-mediatek"
rm -rf "$UB_DIR/patches" # 物理移除：旧补丁会导致 2024.10 校验失败
mkdir -p "$UB_DIR/files"
[ -f "${SRC_DIR}/mt7981b-3000-emmc.dts" ] && cp -v "${SRC_DIR}/mt7981b-3000-emmc.dts" "$UB_DIR/files/sl3000.dts"

printf "include \$(TOPDIR)/rules.mk\n" > "$UB_DIR/Makefile"
printf "include \$(INCLUDE_DIR)/kernel.mk\n" >> "$UB_DIR/Makefile"
printf "PKG_NAME:=uboot-mediatek\nPKG_VERSION:=2024.10\nPKG_RELEASE:=1\n" >> "$UB_DIR/Makefile"
printf "PKG_SOURCE:=u-boot-\$(PKG_VERSION).tar.gz\n" >> "$UB_DIR/Makefile"
printf "PKG_HASH:=skip\n" >> "$UB_DIR/Makefile"
printf "PKG_BUILD_DIR:=\$(BUILD_DIR)/u-boot-\$(PKG_VERSION)\n" >> "$UB_DIR/Makefile"
printf "include \$(INCLUDE_DIR)/package.mk\n\n" >> "$UB_DIR/Makefile"
printf "define Package/uboot-mediatek-mt7981-sl3000-emmc\n  SECTION:=boot\n  CATEGORY:=Boot Loader\n" >> "$UB_DIR/Makefile"
printf "  TITLE:=U-Boot for SL3000 (Physical Fix)\n  DEPENDS:=@TARGET_mediatek\nendef\n\n" >> "$UB_DIR/Makefile"
printf "define Build/Prepare\n\t\$(Build/Prepare/Default)\n" >> "$UB_DIR/Makefile"
printf "\techo \"#define CFG_SYS_INIT_RAM_ADDR 0x40000000\" >> \$(PKG_BUILD_DIR)/include/configs/mt7981.h\n" >> "$UB_DIR/Makefile"
printf "\techo \"#define CFG_SYS_INIT_RAM_SIZE 0x00040000\" >> \$(PKG_BUILD_DIR)/include/configs/mt7981.h\n" >> "$UB_DIR/Makefile"
printf "\techo \"#define CFG_SYS_INIT_SP_ADDR (CFG_SYS_INIT_RAM_ADDR + CFG_SYS_INIT_RAM_SIZE - 0x10)\" >> \$(PKG_BUILD_DIR)/include/configs/mt7981.h\n" >> "$UB_DIR/Makefile"
printf "\tcp ./files/sl3000.dts \$(PKG_BUILD_DIR)/arch/arm/dts/mt7981-sl3000-emmc.dts\n" >> "$UB_DIR/Makefile"
# 物理修复：使用 \$\$\$\$ 深度转义，确保在 Makefile->Shell 中结果为 $
printf "\tsed -i '/dtb-\$\$(CONFIG_ARCH_MEDIATEK) +=/ s/\$\$/ mt7981-sl3000-emmc.dtb/' \$(PKG_BUILD_DIR)/arch/arm/dts/Makefile\n" >> "$UB_DIR/Makefile"
printf "\tcp \$(PKG_BUILD_DIR)/configs/mt7981_emmc_rfb_defconfig \$(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig\n" >> "$UB_DIR/Makefile"
printf "\tsed -i 's/DEFAULT_DEVICE_TREE=.*/DEFAULT_DEVICE_TREE=\"mt7981-sl3000-emmc\"/' \$(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig\n" >> "$UB_DIR/Makefile"
printf "\techo \"CONFIG_TEXT_BASE=0x41e00000\" >> \$(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig\nendef\n\n" >> "$UB_DIR/Makefile"
printf "define Build/Compile\n\t\$(MAKE) -C \$(PKG_BUILD_DIR) mt7981_sl3000_emmc_defconfig\n" >> "$UB_DIR/Makefile"
printf "\t\$(MAKE) -C \$(PKG_BUILD_DIR) CROSS_COMPILE=\$(TARGET_CROSS) DEVICE_DTS=mt7981-sl3000-emmc\nendef\n\n" >> "$UB_DIR/Makefile"
printf "define Package/uboot-mediatek-mt7981-sl3000-emmc/install\n\t\$(INSTALL_DIR) \$(1)\n" >> "$UB_DIR/Makefile"
printf "\t\$(CP) \$(PKG_BUILD_DIR)/u-boot.bin \$(1)/u-boot-sl3000.bin\nendef\n\n" >> "$UB_DIR/Makefile"
printf "\$(eval \$(call BuildPackage,uboot-mediatek-mt7981-sl3000-emmc))\n" >> "$UB_DIR/Makefile"

# 4. 🔥 [ATF 物理绝杀：移除旧补丁]
ATF_DIR="package/boot/arm-trusted-firmware-mediatek"
rm -rf "$ATF_DIR/patches" # 物理隔离
mkdir -p "$ATF_DIR/files"
[ -f "${SRC_DIR}/mt7981b-3000-emmc.dts" ] && cp -v "${SRC_DIR}/mt7981b-3000-emmc.dts" "$ATF_DIR/files/mt7981-sl3000-emmc.dts"

printf "include \$(TOPDIR)/rules.mk\n\n" > "$ATF_DIR/Makefile"
printf "PKG_NAME:=arm-trusted-firmware-mediatek\nPKG_RELEASE:=1\n\n" >> "$ATF_DIR/Makefile"
printf "PKG_SOURCE_PROTO:=git\nPKG_SOURCE_URL=https://github.com/mtk-openwrt/arm-trusted-firmware.git\n" >> "$ATF_DIR/Makefile"
printf "PKG_SOURCE_DATE:=2025-07-11\n" >> "$ATF_DIR/Makefile"
printf "PKG_SOURCE_VERSION:=78a0dfd927bb00ce973a1f8eb4079df0f755887a\n" >> "$ATF_DIR/Makefile"
printf "PKG_MIRROR_HASH:=skip\n\n" >> "$ATF_DIR/Makefile"
printf "include \$(INCLUDE_DIR)/kernel.mk\ninclude \$(INCLUDE_DIR)/trusted-firmware-a.mk\ninclude \$(INCLUDE_DIR)/package.mk\n\n" >> "$ATF_DIR/Makefile"
printf "define Trusted-Firmware-A/Default\n  BUILD_TARGET:=mediatek\n  TFA_IMAGE:=bl2.img bl31.bin\n  HIDDEN:=y\n  PLAT:=mt7981\nendef\n\n" >> "$ATF_DIR/Makefile"
printf "define Trusted-Firmware-A/mt7981-sl3000-emmc\n  NAME:=SL3000 (eMMC, DDR3 1866)\n  BOOT_DEVICE:=emmc\n  BUILD_SUBTARGET:=filogic\n  DDR_TYPE:=ddr3\n  DDR3_FREQ_1866:=1\nendef\n\n" >> "$ATF_DIR/Makefile"
printf "TFA_TARGETS:=mt7981-sl3000-emmc\n\n" >> "$ATF_DIR/Makefile"
printf "define Build/Prepare\n\t\$(Build/Prepare/Default)\n" >> "$ATF_DIR/Makefile"
printf "\tcp ./files/mt7981-sl3000-emmc.dts \$(PKG_BUILD_DIR)/plat/mediatek/mt7981/mt7981-sl3000-emmc.dts\nendef\n\n" >> "$ATF_DIR/Makefile"
printf "define Package/trusted-firmware-a/install\n\t\$(INSTALL_DIR) \$(STAGING_DIR_IMAGE)\n" >> "$ATF_DIR/Makefile"
printf "\t\$(INSTALL_DATA) \$(PKG_BUILD_DIR)/build/\$(PLAT)/release/bl2.img \$(STAGING_DIR_IMAGE)/\$(BUILD_VARIANT)-bl2.img\n" >> "$ATF_DIR/Makefile"
printf "\t\$(INSTALL_DATA) \$(PKG_BUILD_DIR)/build/\$(PLAT)/release/bl31.bin \$(STAGING_DIR_IMAGE)/\$(BUILD_VARIANT)-bl31.bin\nendef\n\n" >> "$ATF_DIR/Makefile"
printf "\$(eval \$(call BuildPackage/Trusted-Firmware-A))\n" >> "$ATF_DIR/Makefile"

# 5. [环境注入]
printf "CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_3000-emmc=y\n" > .config
printf "CONFIG_PACKAGE_uboot-mediatek-mt7981-sl3000-emmc=y\nCONFIG_PACKAGE_trusted-firmware-a-mt7981-sl3000-emmc=y\n" >> .config

if [ -f "${SRC_DIR}/mt7981b-3000-emmc.dts" ]; then
    find target/linux/mediatek/ -name "dts" -type d | while read -r dts_dir; do
        mkdir -p "$dts_dir/mediatek"
        cp -v "${SRC_DIR}/mt7981b-3000-emmc.dts" "$dts_dir/mediatek/"
    done
fi
if [ -f "${SRC_DIR}/filogic.mk" ]; then
    sed -i '/define Device\/sl3000-emmc/,/endef/d' target/linux/mediatek/image/filogic.mk || true
    cat "${SRC_DIR}/filogic.mk" >> target/linux/mediatek/image/filogic.mk
fi
