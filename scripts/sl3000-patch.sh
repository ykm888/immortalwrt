#!/bin/bash
# 物理熔断：修复 feeds 重复报错 & 确保 U-Boot 构建
# 严禁使用 EOF | 结构死锁 | 原文照抄
set -eo pipefail

# 1. 物理注入源 (增加防重复物理检查)
if ! grep -q "helloworld" feeds.conf.default; then
    printf "src-git helloworld https://github.com/fw876/helloworld\n" >> feeds.conf.default
fi

# 2. 物理对齐 24.10 路径
mkdir -p target/linux/mediatek/dts/mediatek
mkdir -p target/linux/mediatek/image/

# 3. 物理注入 DTS 原文 (1GB RAM & 成功案例逻辑)
DTS_FILE="target/linux/mediatek/dts/mediatek/mt7981b-sl-3000-emmc.dts"
printf "/dts-v1/;\n#include <dt-bindings/gpio/gpio.h>\n#include <dt-bindings/input/input.h>\n#include <dt-bindings/leds/common.h>\n#include \"mt7981.dtsi\"\n\n" > "$DTS_FILE"
printf "/ {\n\tmodel = \"SL-3000 1GB-RAM 128GB-eMMC Custom\";\n\tcompatible = \"sl,3000-emmc\", \"mediatek,mt7981\";\n\n" >> "$DTS_FILE"
printf "\taliases {\n\t\tserial0 = &uart0;\n\t\tled-boot = &status_red_led;\n\t\tled-failsafe = &status_red_led;\n\t\tled-running = &status_green_led;\n\t\tled-upgrade = &status_blue_led;\n\t};\n\n" >> "$DTS_FILE"
printf "\tchosen {\n\t\tbootargs = \"root=PARTLABEL=rootfs rootwait\";\n\t\tstdout-path = \"serial0:115200n8\";\n\t};\n\n" >> "$DTS_FILE"
printf "\tmemory@40000000 {\n\t\treg = <0 0x40000000 0 0x40000000>;\n\t};\n\n" >> "$DTS_FILE"
printf "\tgpio-keys {\n\t\tcompatible = \"gpio-keys\";\n\t\tbutton-mesh { label = \"mesh\"; linux,code = <BTN_9>; linux,input-type = <EV_SW>; gpios = <&pio 0 GPIO_ACTIVE_LOW>; };\n\t\tbutton-reset { label = \"reset\"; linux,code = <KEY_RESTART>; gpios = <&pio 1 GPIO_ACTIVE_LOW>; };\n\t};\n\n" >> "$DTS_FILE"
printf "\tgpio-leds {\n\t\tcompatible = \"gpio-leds\";\n\t\tstatus_red_led: led-0 { label = \"red:status\"; gpios = <&pio 10 GPIO_ACTIVE_LOW>; };\n\t\tstatus_green_led: led-1 { label = \"green:status\"; gpios = <&pio 11 GPIO_ACTIVE_LOW>; };\n\t\tstatus_blue_led: led-2 { label = \"blue:status\"; gpios = <&pio 12 GPIO_ACTIVE_LOW>; };\n\t};\n};\n\n" >> "$DTS_FILE"
printf "&eth {\n\tstatus = \"okay\";\n\tgmac0: mac@0 { compatible = \"mediatek,eth-mac\"; reg = <0>; phy-mode = \"2500base-x\";\n\t\tfixed-link { speed = <2500>; full-duplex; pause; };\n\t};\n\tmdio: mdio-bus {\n\t\t#address-cells = <1>; #size-cells = <0>;\n\t\tswitch@0 {\n\t\t\tcompatible = \"mediatek,mt7531\"; reg = <31>; reset-gpios = <&pio 39 0>;\n\t\t\tports {\n\t\t\t\t#address-cells = <1>; #size-cells = <0>;\n\t\t\t\tport@0 { reg = <0>; label = \"lan1\"; };\n\t\t\t\tport@1 { reg = <1>; label = \"lan2\"; };\n\t\t\t\tport@2 { reg = <2>; label = \"lan3\"; };\n\t\t\t\tport@3 { reg = <3>; label = \"wan\"; };\n\t\t\t\tport@6 { reg = <6>; label = \"cpu\"; ethernet = <&gmac0>; phy-mode = \"2500base-x\";\n\t\t\t\t\tfixed-link { speed = <2500>; full-duplex; pause; };\n\t\t\t\t};\n\t\t\t};\n\t\t};\n\t};\n};\n\n" >> "$DTS_FILE"
printf "&mmc0 {\n\tbus-width = <8>; cap-mmc-highspeed; max-frequency = <52000000>;\n\tno-sd; no-sdio; non-removable;\n\tpinctrl-names = \"default\", \"state_uhs\";\n\tpinctrl-0 = <&mmc0_pins_default>; pinctrl-1 = <&mmc0_pins_uhs>;\n\tvmmc-supply = <&reg_3p3v>; status = \"okay\";\n};\n\n&uart0 { status = \"okay\"; };\n&watchdog { status = \"okay\"; };\n&wifi { nvmem-cells = <&eeprom_factory_0>; nvmem-cell-names = \"eeprom\"; status = \"okay\";\n\tband@1 { reg = <1>; nvmem-cells = <&macaddr_factory_4 1>; nvmem-cell-names = \"mac-address\"; };\n};\n&usb_phy { status = \"okay\"; };\n&xhci { status = \"okay\"; };\n" >> "$DTS_FILE"

# 4. 物理修复 MK 并开启 U-Boot 生成 (IMAGE 列表补全)
MK_FILE="target/linux/mediatek/image/filogic.mk"
printf "DTS_DIR := \$(DTS_DIR)/mediatek\n\ndefine Build/mt7981-bl31-uboot\n\tcat \$(STAGING_DIR_IMAGE)/mt7981_\$1-u-boot.fip >> \$@\nendef\n\n" > "$MK_FILE"
printf "define Device/sl_3000-emmc\n" >> "$MK_FILE"
printf "  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000-eMMC\n" >> "$MK_FILE"
printf "  DEVICE_DTS := mt7981b-sl-3000-emmc\n" >> "$MK_FILE"
printf "  DEVICE_DTS_DIR := ../dts\n" >> "$MK_FILE"
printf "  SUPPORTED_DEVICES := sl,3000-emmc\n" >> "$MK_FILE"
printf "  IMAGES := sysupgrade.bin fip.bin\n" >> "$MK_FILE"
printf "  IMAGE/fip.bin := mt7981-bl31-uboot sl_3000-emmc\n" >> "$MK_FILE"
printf "  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\n" >> "$MK_FILE"
printf "  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools e2fsprogs f2fsck mkf2fs kmod-zram zram-swap\n" >> "$MK_FILE"
printf "endef\nTARGET_DEVICES += sl_3000-emmc\n" >> "$MK_FILE"

# 5. 物理校准 .config (锁定 24.10 内核与 U-Boot 编译开关)
if [ -f ".config" ]; then
    sed -i 's/CONFIG_LINUX_5_4=y/# CONFIG_LINUX_5_4 is not set/g' .config
    sed -i '/CONFIG_LINUX_5_4 is not set/a CONFIG_LINUX_6_6=y' .config
    echo "CONFIG_PACKAGE_u-boot-mt7981_sl_3000-emmc=y" >> .config
fi
