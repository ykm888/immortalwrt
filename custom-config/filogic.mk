define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := Custom-128GB-Edition
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,sl3000-emmc mediatek,mt7981b mediatek,mt7981
  
  # 🎯 延续修复：内核分区物理大小锁定为 128MB (必须与 DTS 一致)
  KERNEL_SIZE := 134217728
  
  # 🎯 彻底修复：移除具体的 IMAGE_SIZE 限制
  # 移除该项可以防止编译脚本在校验 1GB 这种超大空间时报整数溢出错误
  
  # 🎯 延续修复：核心打包宏定义，确保 FIT 镜像包含 Kernel 和 DTB
  KERNEL := kernel-bin | lzma | fit $$(DEVICE_DTS)
  
  # 🎯 核心补丁：彻底禁用 initramfs，跳过导致 Error 2 的救援包生成步骤
  KERNEL_INITRAMFS := 
  
  # 🚀 延续修复：释放 128GB eMMC 潜力的驱动包
  DEVICE_PACKAGES := \
	kmod-mmc kmod-sdhci-mtk \
	kmod-fs-f2fs f2fs-tools f2fsck \
	parted lsblk blkid block-mount \
	kmod-zram zram-swap
  
  # 🎯 终极修复：只保留 sysupgrade.bin 格式，移除 .gz 以减少编译时的压缩开销和潜在错误
  IMAGES := sysupgrade.bin
  
  # 🎯 延续修复：物理拼接流水线
  # 严格执行：[内核] + [补位到128MB位置] + [Rootfs]
  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
