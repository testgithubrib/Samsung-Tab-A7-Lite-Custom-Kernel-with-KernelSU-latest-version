#!/usr/bin/env bash
set -e

# ========================================================
# Samsung Tab A7 Lite (SM-T220) Custom Kernel Build Script
# ========================================================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$BASE_DIR/kernel"
STOCK_DIR="$BASE_DIR/stock"
TOOLCHAIN_DIR="$BASE_DIR/toolchain"
OUT_DIR="$KERNEL_DIR/out"

echo "========================================================"
echo " Starting Build for SM-T220 (gta7litewifi) KernelSU    "
echo "========================================================"

# Check toolchain setup
CLANG_DIR="$TOOLCHAIN_DIR/clang/host/linux-x86/clang-r383902"
GCC_DIR="$TOOLCHAIN_DIR/gcc/linux-x86/aarch64/aarch64-linux-android-4.9"

if [ ! -d "$CLANG_DIR" ] || [ ! -d "$GCC_DIR" ]; then
    echo ">> Prebuilt toolchains not found in $TOOLCHAIN_DIR."
    echo ">> Downloading required Android AOSP toolchains..."
    mkdir -p "$CLANG_DIR" "$GCC_DIR"

    if [ ! -f "$CLANG_DIR/bin/clang" ]; then
        echo "   Downloading Clang r383902..."
        curl -fsSL "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/android11-release/clang-r383902.tar.gz" | tar -xz -C "$CLANG_DIR"
    fi

    if [ ! -f "$GCC_DIR/bin/aarch64-linux-androidkernel-gcc" ] && [ ! -f "$GCC_DIR/bin/aarch64-linux-android-gcc" ]; then
        echo "   Downloading GCC 4.9 (aarch64)..."
        curl -fsSL "https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/heads/android11-release.tar.gz" | tar -xz -C "$GCC_DIR"
    fi
fi

# Determine GCC prefix
if [ -f "$GCC_DIR/bin/aarch64-linux-androidkernel-gcc" ]; then
    CROSS_PREFIX="$GCC_DIR/bin/aarch64-linux-androidkernel-"
else
    CROSS_PREFIX="$GCC_DIR/bin/aarch64-linux-android-"
fi

export ARCH=arm64
export SUBARCH=arm64
export CC="$CLANG_DIR/bin/clang"
export CROSS_COMPILE="$CROSS_PREFIX"
export CLANG_TRIPLE=aarch64-linux-gnu-
export KCFLAGS="-w"
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

# Make sure kernelsu symlink is in place
if [ ! -e "$KERNEL_DIR/drivers/kernelsu" ]; then
    echo ">> Creating KernelSU symlink..."
    ln -s ../KernelSU/kernel "$KERNEL_DIR/drivers/kernelsu"
fi

mkdir -p "$OUT_DIR"

echo ">> Generating defconfig..."
make -C "$KERNEL_DIR" O="$OUT_DIR" KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y gta7litewifi_defconfig

echo ">> Compiling kernel with $(nproc) threads..."
make -C "$KERNEL_DIR" O="$OUT_DIR" KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y -j"$(nproc)"

IMAGE_GZ="$OUT_DIR/arch/arm64/boot/Image.gz"
if [ ! -f "$IMAGE_GZ" ]; then
    echo ">> Image.gz not in out/, checking gzip..."
    gzip -9 -c "$OUT_DIR/arch/arm64/boot/Image" > "$IMAGE_GZ"
fi

# Copy Image & Image.gz to arch/arm64/boot
mkdir -p "$KERNEL_DIR/arch/arm64/boot"
cp "$OUT_DIR/arch/arm64/boot/Image" "$KERNEL_DIR/arch/arm64/boot/Image"
cp "$IMAGE_GZ" "$KERNEL_DIR/arch/arm64/boot/Image.gz"

echo ">> Repacking boot.img (32 MB with Samsung SEANDROIDENFORCE)..."
python3 "$BASE_DIR/repack_boot.py" \
    "$IMAGE_GZ" \
    "$STOCK_DIR/stock_ramdisk.cpio.gz" \
    "$STOCK_DIR/stock_dtb.dtb" \
    "$BASE_DIR/boot.img"

echo "========================================================"
echo " [SUCCESS] Kernel and boot.img built successfully!     "
echo " Final output: $BASE_DIR/boot.img                       "
echo "========================================================"
