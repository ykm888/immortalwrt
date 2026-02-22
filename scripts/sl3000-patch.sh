#!/bin/bash
# 物理熔断：SL3000 24.10 内核/引导全链路彻底解决版
set -eo pipefail

WORKDIR="openwrt"
cd "${WORKDIR}"

# 1. [物理清场]
./scripts/feeds update -a
./scripts/feeds install -a -f
rm -rf build_dir/target-aarch64_cortex-a53_musl/u-boot-2024.10
rm -rf build_dir/target-aarch64_cortex-a53_musl/arm-trusted-firmware-mediatek*

# 2. [源码物理装载]
mkdir -p dl
curl -L "https://github.com/u-boot/u-boot/archive/refs/tags/v2024.10.tar.gz" -o dl/u-boot-2024.10.tar.gz

# 3. [U-Boot 物理注入]
UB_DIR="package/boot/uboot-mediatek"
rm -rf "$UB_DIR/patches"
mkdir -p "$UB_DIR/files"

# --- 物理修复 1：注入 U-Boot DTS (使用 #include 语法) ---
printf "/dts-v1/;\n#include \"mt7981.dtsi\"\n/ {\n\tmodel = \"SL3000-eMMC\";\n\tcompatible = \"mediatek,mt7981-spim-snand-rfb\", \"mediatek,mt7981\";\n\taliases {\n\t\tmmc0 = &mmc0;\n\t};\n};\n&mmc0 {\n\tstatus = \"okay\";\n\tbus-width = <8>;\n\tmax-frequency = <52000000>;\n\tcap-mmc-highspeed;\n\tnon-removable;\n};\n" > "$UB_DIR/files/sl3000.dts"

# --- 物理重构 U-Boot Makefile (锁定 sed 定界符) ---
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
printf "\tsed -i 's|dtb-\$\$(CONFIG_ARCH_MEDIATEK) +=|dtb-\$\$(CONFIG_ARCH_MEDIATEK) += mt7981-sl3000-emmc.dtb|' \$(PKG_BUILD_DIR)/arch/arm/dts/Makefile\n" >> "$UB_DIR/Makefile"
printf "\tcp \$(PKG_BUILD_DIR)/configs/mt7981_emmc_rfb_defconfig \$(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig\n" >> "$UB_DIR/Makefile"
printf "\tsed -i 's/DEFAULT_DEVICE_TREE=.*/DEFAULT_DEVICE_TREE=\"mt7981-sl3000-emmc\"/' \$(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig\n" >> "$UB_DIR/Makefile"
printf "\techo \"CONFIG_TEXT_BASE=0x41e00000\" >> \$(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig\nendef\n\n" >> "$UB_DIR/Makefile"
printf "define Build/Compile\n\t\$(MAKE) -C \$(PKG_BUILD_DIR) mt7981_sl3000_emmc_defconfig\n" >> "$UB_DIR/Makefile"
printf "\t\$(MAKE) -C \$(PKG_BUILD_DIR) CROSS_COMPILE=\$(TARGET_CROSS) DEVICE_DTS=mt7981-sl3000-emmc\nendef\n\n" >> "$UB_DIR/Makefile"
printf "define Package/uboot-mediatek-mt7981-sl3000-emmc/install\n\t\$(INSTALL_DIR) \$(1)\n" >> "$UB_DIR/Makefile"
printf "\t\$(CP) \$(PKG_BUILD_DIR)/u-boot.bin \$(1)/u-boot-sl3000.bin\nendef\n\n" >> "$UB_DIR/Makefile"
printf "\$(eval \$(call BuildPackage,uboot-mediatek-mt7981-sl3000-emmc))\n" >> "$UB_DIR/Makefile"

# --- 物理修复 2：注入内核 DTS (解决 target/linux 报错) ---
# 必须物理创建内核目录并生成文件，名称必须对齐 DEVICE_DTS 定义
mkdir -p target/linux/mediatek/dts/
printf "/dts-v1/;\n#include \"mt7981.dtsi\"\n/ {\n\tmodel = \"SL3000-eMMC\";\n\tcompatible = \"mediatek,mt7981-spim-snand-rfb\", \"mediatek,mt7981\";\n};\n&mmc0 {\n\tstatus = \"okay\";\n\tbus-width = <8>;\n\tmax-frequency = <52000000>;\n\tcap-mmc-highspeed;\n\tnon-removable;\n};\n" > target/linux/mediatek/dts/mt7981b-3000-emmc.dts

# 4. [filogic.mk 物理重构] 锁死分区与设备定义
TARGET_MK="target/linux/mediatek/image/filogic.mk"
sed -i '/define Device\/sl3000-emmc/,/endef/d' $TARGET_MK || true
printf "\ndefine Device/sl3000-emmc\n  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000-eMMC\n  DEVICE_DTS := mt7981b-3000-emmc\n  DEVICE_DTS_DIR := \$(DTS_DIR)/mediatek\n  SUPPORTED_DEVICES := sl,3000-emmc\n\n  KERNEL_SIZE := 134217728\n  IMAGE_SIZE := 536870912\n\n  KERNEL := kernel-bin | lzma | append-dtb\n  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \\\\\n                    parted lsblk blkid block-mount kmod-zram zram-swap \\\\\n                    luci-app-diskman uboot-envtools\n\n  IMAGES := sysupgrade.bin\n  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | check-size | append-metadata\nendef\nTARGET_DEVICES += sl3000-emmc\n" >> $TARGET_MK

# 5. [环境最终锁定]
printf "CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y\n" > .config
printf "CONFIG_PACKAGE_uboot-mediatek-mt7981-sl3000-emmc=y\n" >> .config
