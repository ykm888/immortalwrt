#!/bin/bash
# 物理熔断：SL3000 24.10 全链路彻底修复与内核源码注入版
set -eo pipefail

WORKDIR="openwrt"
cd "${WORKDIR}"

# 1. [物理清场与初始化]
./scripts/feeds update -a
./scripts/feeds install -a -f
rm -rf build_dir/target-aarch64_cortex-a53_musl/u-boot-2024.10
rm -rf build_dir/target-aarch64_cortex-a53_musl/arm-trusted-firmware-mediatek*

# 2. [U-Boot 物理注入逻辑]
UB_DIR="package/boot/uboot-mediatek"
mkdir -p "$UB_DIR/files"
DTS_UBOOT="/dts-v1/;\n#include \"mt7981.dtsi\"\n/ {\n\tmodel = \"SL3000-eMMC\";\n\tcompatible = \"mediatek,mt7981-spim-snand-rfb\", \"mediatek,mt7981\";\n\taliases {\n\t\tmmc0 = &mmc0;\n\t};\n};\n&mmc0 {\n\tstatus = \"okay\";\n\tbus-width = <8>;\n\tmax-frequency = <52000000>;\n\tcap-mmc-highspeed;\n\tnon-removable;\n};\n"
printf "$DTS_UBOOT" > "$UB_DIR/files/sl3000.dts"

# 物理重构 U-Boot Makefile
printf "include \$(TOPDIR)/rules.mk\ninclude \$(INCLUDE_DIR)/kernel.mk\nPKG_NAME:=uboot-mediatek\nPKG_VERSION:=2024.10\nPKG_RELEASE:=1\n" > "$UB_DIR/Makefile"
printf "PKG_SOURCE:=u-boot-\$(PKG_VERSION).tar.gz\nPKG_HASH:=skip\nPKG_BUILD_DIR:=\$(BUILD_DIR)/u-boot-\$(PKG_VERSION)\ninclude \$(INCLUDE_DIR)/package.mk\n\n" >> "$UB_DIR/Makefile"
printf "define Package/uboot-mediatek-mt7981-sl3000-emmc\n  SECTION:=boot\n  CATEGORY:=Boot Loader\n  TITLE:=U-Boot for SL3000\n  DEPENDS:=@TARGET_mediatek\nendef\n\n" >> "$UB_DIR/Makefile"
printf "define Build/Prepare\n\t\$(Build/Prepare/Default)\n\tcp ./files/sl3000.dts \$(PKG_BUILD_DIR)/arch/arm/dts/mt7981-sl3000-emmc.dts\n" >> "$UB_DIR/Makefile"
printf "\tsed -i 's|dtb-\$\$(CONFIG_ARCH_MEDIATEK) +=|dtb-\$\$(CONFIG_ARCH_MEDIATEK) += mt7981-sl3000-emmc.dtb|' \$(PKG_BUILD_DIR)/arch/arm/dts/Makefile\n" >> "$UB_DIR/Makefile"
printf "\tcp \$(PKG_BUILD_DIR)/configs/mt7981_emmc_rfb_defconfig \$(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig\n" >> "$UB_DIR/Makefile"
printf "\tsed -i 's/DEFAULT_DEVICE_TREE=.*/DEFAULT_DEVICE_TREE=\"mt7981-sl3000-emmc\"/' \$(PKG_BUILD_DIR)/configs/mt7981_sl3000_emmc_defconfig\n" >> "$UB_DIR/Makefile"
printf "endef\n\ndefine Build/Compile\n\t\$(MAKE) -C \$(PKG_BUILD_DIR) mt7981_sl3000_emmc_defconfig\n\t\$(MAKE) -C \$(PKG_BUILD_DIR) CROSS_COMPILE=\$(TARGET_CROSS)\nendef\n\n" >> "$UB_DIR/Makefile"
printf "define Package/uboot-mediatek-mt7981-sl3000-emmc/install\n\t\$(INSTALL_DIR) \$(1)\n\t\$(CP) \$(PKG_BUILD_DIR)/u-boot.bin \$(1)/u-boot-sl3000.bin\nendef\n\n\$(eval \$(call BuildPackage,uboot-mediatek-mt7981-sl3000-emmc))\n" >> "$UB_DIR/Makefile"

# --- 🔥 3. 物理绝杀：同步注入内核源码 DTS ---
DTS_KERNEL="/dts-v1/;\n#include \"mt7981.dtsi\"\n/ {\n\tmodel = \"SL3000-eMMC\";\n\tcompatible = \"mediatek,mt7981-spim-snand-rfb\", \"mediatek,mt7981\";\n};\n&mmc0 {\n\tstatus = \"okay\";\n\tbus-width = <8>;\n\tmax-frequency = <52000000>;\n\tcap-mmc-highspeed;\n\tnon-removable;\n};\n"
# 物理路径 1：OpenWrt 镜像构建目录
mkdir -p target/linux/mediatek/dts/
printf "$DTS_KERNEL" > target/linux/mediatek/dts/mt7981b-3000-emmc.dts

# 物理路径 2：强行寻找解压后的内核源码目录并注入 (彻底解决 No such file 报错)
# 这个步骤在 workflow 的编译过程中会生效
KERNEL_DTS_DIR=\$(find build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/ -name "mediatek" -type d | grep "arch/arm64/boot/dts/mediatek" | head -n 1)
if [ -n "\$KERNEL_DTS_DIR" ]; then
    printf "$DTS_KERNEL" > "\$KERNEL_DTS_DIR/mt7981b-3000-emmc.dts"
fi

# 4. [filogic.mk 物理锁定]
TARGET_MK="target/linux/mediatek/image/filogic.mk"
sed -i '/define Device\/sl3000-emmc/,/endef/d' $TARGET_MK || true
printf "\ndefine Device/sl3000-emmc\n  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000-eMMC\n  DEVICE_DTS := mt7981b-3000-emmc\n  SUPPORTED_DEVICES := sl,3000-emmc\n  KERNEL_SIZE := 134217728\n  IMAGE_SIZE := 536870912\n  KERNEL := kernel-bin | lzma | append-dtb\n  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \\\\\n                    parted lsblk blkid block-mount kmod-zram zram-swap \\\\\n                    luci-app-diskman uboot-envtools\n  IMAGES := sysupgrade.bin\n  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | check-size | append-metadata\nendef\nTARGET_DEVICES += sl3000-emmc\n" >> $TARGET_MK

# 5. [环境注入]
printf "CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y\n" > .config
printf "CONFIG_PACKAGE_uboot-mediatek-mt7981-sl3000-emmc=y\n" >> .config
