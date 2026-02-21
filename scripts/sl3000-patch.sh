#!/bin/bash
# 物理熔断：SL3000 24.10 字符转义与补丁隔离版
set -eo pipefail

WORKDIR="openwrt"
# 预设 custom-config 兼容性路径，若不存在则回退至内置定义
SRC_DIR="custom-config"

cd "${WORKDIR}"

# 1. [物理清场] 延续原文逻辑
./scripts/feeds update -a
./scripts/feeds install -a -f
rm -rf build_dir/target-aarch64_cortex-a53_musl/u-boot-2024.10
rm -rf build_dir/target-aarch64_cortex-a53_musl/arm-trusted-firmware-mediatek*

# 2. [U-Boot 物理重构] 物理移除旧 patches 确保 2024.10 纯净度
UB_DIR="package/boot/uboot-mediatek"
rm -rf "$UB_DIR/patches"
mkdir -p "$UB_DIR/files"

# 物理注入 Makefile (不使用 EOF)
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
printf "\tcp ./files/sl3000.dts \$(PKG_BUILD_DIR)/arch/arm/dts/mt7981-sl3000-emmc.dtb\n" >> "$UB_DIR/Makefile"
# 延续深度转义策略
printf "\tsed -i '/dtb-\$\$(CONFIG_ARCH_MEDIATEK) +=/ s/\$\$/ mt7981-sl3000-emmc.dtb/' \$(PKG_BUILD_DIR)/arch/arm/dts/Makefile\n" >> "$UB_DIR/Makefile"
printf "\tcp \$(PKG_BUILD_DIR)/configs/mt7981_emmc_rfb_defconfig \$(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig\n" >> "$UB_DIR/Makefile"
printf "\tsed -i 's/DEFAULT_DEVICE_TREE=.*/DEFAULT_DEVICE_TREE=\"mt7981-sl3000-emmc\"/' \$(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig\n" >> "$UB_DIR/Makefile"
printf "\techo \"CONFIG_TEXT_BASE=0x41e00000\" >> \$(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig\nendef\n\n" >> "$UB_DIR/Makefile"
printf "define Build/Compile\n\t\$(MAKE) -C \$(PKG_BUILD_DIR) mt7981_sl3000_emmc_defconfig\n" >> "$UB_DIR/Makefile"
printf "\t\$(MAKE) -C \$(PKG_BUILD_DIR) CROSS_COMPILE=\$(TARGET_CROSS) DEVICE_DTS=mt7981-sl3000-emmc\nendef\n\n" >> "$UB_DIR/Makefile"
printf "define Package/uboot-mediatek-mt7981-sl3000-emmc/install\n\t\$(INSTALL_DIR) \$(1)\n" >> "$UB_DIR/Makefile"
printf "\t\$(CP) \$(PKG_BUILD_DIR)/u-boot.bin \$(1)/u-boot-sl3000.bin\nendef\n\n" >> "$UB_DIR/Makefile"
printf "\$(eval \$(call BuildPackage,uboot-mediatek-mt7981-sl3000-emmc))\n" >> "$UB_DIR/Makefile"

# 3. [filogic.mk 物理注入] 严禁修改字节数值
TARGET_MK="target/linux/mediatek/image/filogic.mk"
sed -i '/define Device\/sl3000-emmc/,/endef/d' $TARGET_MK || true
printf "\ndefine Device/sl3000-emmc\n  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000-eMMC\n  DEVICE_DTS := mt7981b-3000-emmc\n  DEVICE_DTS_DIR := \$(DTS_DIR)/mediatek\n  SUPPORTED_DEVICES := sl,3000-emmc\n\n  # 物理死锁：字节纯数字，防止 dd 报错\n  KERNEL_SIZE := 134217728\n  IMAGE_SIZE := 536870912\n\n  KERNEL := kernel-bin | lzma | append-dtb\n  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \\\\\n                    parted lsblk blkid block-mount kmod-zram zram-swap \\\\\n                    luci-app-diskman uboot-envtools\n\n  # 物理修复：移除导致 Missing Build 报错的 ARTIFACTS 段落\n  IMAGES := sysupgrade.bin\n  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | check-size | append-metadata\nendef\nTARGET_DEVICES += sl3000-emmc\n" >> $TARGET_MK

# 4. [环境配置]
printf "CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y\n" > .config
printf "CONFIG_PACKAGE_uboot-mediatek-mt7981-sl3000-emmc=y\n" >> .config
