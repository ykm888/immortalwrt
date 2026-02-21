#!/bin/bash

# 1. 物理注入：Device 定义 (严禁画蛇添足，逐行原文追加)
TARGET_MK="target/linux/mediatek/image/filogic.mk"

echo "" >> $TARGET_MK
echo "define Device/sl3000-emmc" >> $TARGET_MK
echo "  DEVICE_VENDOR := SL" >> $TARGET_MK
echo "  DEVICE_MODEL := 3000-eMMC" >> $TARGET_MK
echo "  DEVICE_DTS := mt7981b-3000-emmc" >> $TARGET_MK
echo "  DEVICE_DTS_DIR := \$(DTS_DIR)/mediatek" >> $TARGET_MK
echo "  SUPPORTED_DEVICES := sl,3000-emmc" >> $TARGET_MK
echo "  " >> $TARGET_MK
echo "  # 物理死锁：字节纯数字，防止 dd 报错" >> $TARGET_MK
echo "  KERNEL_SIZE := 134217728" >> $TARGET_MK
echo "  IMAGE_SIZE := 536870912" >> $TARGET_MK
echo "" >> $TARGET_MK
echo "  KERNEL := kernel-bin | lzma | append-dtb" >> $TARGET_MK
echo "  DEVICE_PACKAGES := kmod-mmc kmod-mtk-sd kmod-fs-f2fs f2fs-tools f2fsck \\" >> $TARGET_MK
echo "                    parted lsblk blkid block-mount kmod-zram zram-swap \\" >> $TARGET_MK
echo "                    luci-app-diskman uboot-envtools" >> $TARGET_MK
echo "" >> $TARGET_MK
echo "  # 物理修复：移除导致 Missing Build 报错的 ARTIFACTS 段落" >> $TARGET_MK
echo "  # 镜像生成逻辑" >> $TARGET_MK
echo "  IMAGES := sysupgrade.bin" >> $TARGET_MK
echo "  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | check-size | append-metadata" >> $TARGET_MK
echo "endef" >> $TARGET_MK
echo "TARGET_DEVICES += sl3000-emmc" >> $TARGET_MK

# 2. 物理修复：针对 uboot-mediatek 的 sed 语法报错
# 审计标准：修复缺失的闭合定界符 /，确保脚本在 Makefile 中正确定位 dtb- += 行
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"

if [ -f "$UBOOT_MAKEFILE" ]; then
    echo "执行物理修复：修正 uboot Makefile 中的 sed 语法..."
    # 修复逻辑：s/目标/替换/ 结构闭合，防止 unterminated s command
    sed -i '/dtb- +=/ s/$/ mt7981-sl3000-emmc.dtb/' $UBOOT_MAKEFILE
fi

# 3. 物理检查 (审计自检)
if grep -q "sl3000-emmc" $TARGET_MK; then
    echo "物理检查通过：Device 定义已写入。"
else
    echo "报错熔断：Makefile 写入失败。"
    exit 1
fi
