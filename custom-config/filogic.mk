define Device/sl3000-emmc
  DEVICE_VENDOR := SL3000
  DEVICE_MODEL := sl3000-emmc
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  # 🎯 核心修复：确保支持列表包含设备名，防止 root-mediatek 路径丢失
  SUPPORTED_DEVICES := sl,sl3000-emmc mediatek,mt7981b mediatek,mt7981
  
  # 🎯 延续修复：128MB 内核物理对齐 (必须与 DTS 的 partition@380000 严格对应)
  KERNEL_SIZE := 134217728
  
  # 🎯 彻底解决 root.squashfs Error 1：
  # 设置编译时的静态 Rootfs 上限为 512MB。
  # 既能避开 32 位脚本溢出，又保证了打包路径的正确生成。
  BOARD_ROOTFS_PARTSIZE := 524288
  
  # 🎯 延续修复：核心打包宏，确保 FIT 镜像同时包含 Kernel 和 DTB
  KERNEL := kernel-bin | lzma | fit $$(DEVICE_DTS)
  
  # 🎯 核心补丁：禁用救援包，彻底跳过之前反复报错的 initramfs 流程
  KERNEL_INITRAMFS := 
  
  # 🚀 延续修复：释放 128GB eMMC 和 1GB RAM 潜力的必备驱动包
  DEVICE_PACKAGES := \
	kmod-mmc kmod-sdhci-mtk \
	kmod-fs-f2fs f2fs-tools f2fsck \
	parted lsblk blkid block-mount \
	kmod-zram zram-swap
  
  # 🎯 终极优化：只输出 bin 格式，防止大文件在 Actions 环境下压缩超时或 OOM
  IMAGES := sysupgrade.bin
  
  # 🎯 延续修复：物理拼接流水线 [内核] + [对齐补位到 128MB] + [Rootfs]
  IMAGE/sysupgrade.bin := append-kernel | pad-to 134217728 | append-rootfs | append-metadata
endef
TARGET_DEVICES += sl3000-emmc
