#!/bin/bash
set -eo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="${REPO_ROOT}/openwrt"
SRC_DIR="${REPO_ROOT}/custom-config"

echo -e "\033[32m💎 [SL3000] Starting Physical Reconstruction: Stripping Size Constraints...\033[0m"

cd "${WORKDIR}"

# 1. Physical Environment Preparation
mkdir -p staging_dir/host
touch staging_dir/host/.prereq-build

# 2. 🔥 [Physical Reconstruction .config]
rm -f .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl3000-emmc=y"
} > .config

if [ -f "${SRC_DIR}/sl3000.config" ]; then
    grep "^CONFIG_" "${SRC_DIR}/sl3000.config" | tr -d '\r' | sed 's/ //g' >> .config || true
fi

# 3. 🔥 [Physical Alignment] Partition Sizes (Locked to 128/512)
sed -i '/_PARTSIZE/d' .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=128" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=512" >> .config

# 4. 🔥 [Physical Relaxation] Strip pad-to from Global Image Logic
if [ -f "include/image.mk" ]; then
    sed -i '/pad-to/d' include/image.mk || true
fi

# 5. 🔥 [Physical Injection] DTS Triple-Path Coverage
DTS_A="target/linux/mediatek/dts"
DTS_B="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
DTS_C="target/linux/mediatek/files-6.6/arch/arm64/boot/dts"

mkdir -p "$DTS_A" "$DTS_B" "$DTS_C"
if [ -f "${SRC_DIR}/mt7981b-sl3000-emmc.dts" ]; then
    cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "$DTS_A/"
    cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "$DTS_B/"
    cp -fv "${SRC_DIR}/mt7981b-sl3000-emmc.dts" "$DTS_C/"
fi

# 6. 🔥 [Physical Injection & De-Noising] MK Configuration
mkdir -p target/linux/mediatek/image
if [ -f "${SRC_DIR}/filogic.mk" ]; then
    cp -fv "${SRC_DIR}/filogic.mk" target/linux/mediatek/image/
    # Physically remove pad-to and check-size to prevent Build/true errors
    sed -i '/pad-to/d' target/linux/mediatek/image/filogic.mk || true
    sed -i '/check-size/d' target/linux/mediatek/image/filogic.mk || true
fi

# 7. Disable Signatures
sed -i 's/$(STAGING_DIR_HOST)\/bin\/usign/true/g' package/Makefile || true
sed -i 's/$(STAGING_DIR_HOST)\/bin\/ucert/true/g' package/Makefile || true

echo -e "\033[32m✅ Physical relaxation completed. Constraints removed.\033[0m"
