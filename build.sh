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

# Determine Clang
if [ -f "$TOOLCHAIN_DIR/clang/host/linux-x86/clang-r383902/bin/clang" ]; then
    CLANG_BIN="$TOOLCHAIN_DIR/clang/host/linux-x86/clang-r383902/bin/clang"
elif command -v clang >/dev/null 2>&1; then
    CLANG_BIN="$(command -v clang)"
else
    echo ">> Clang not found! Please install clang."
    exit 1
fi

# Determine Cross-compiler (GCC / Binutils)
if [ -f "$TOOLCHAIN_DIR/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-gcc" ]; then
    CROSS_PREFIX="$TOOLCHAIN_DIR/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-"
elif [ -f "$TOOLCHAIN_DIR/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-gcc" ]; then
    CROSS_PREFIX="$TOOLCHAIN_DIR/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
elif command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
    CROSS_PREFIX="aarch64-linux-gnu-"
else
    CROSS_PREFIX="aarch64-linux-gnu-"
fi

echo ">> Using Compiler: $CLANG_BIN"
echo ">> Using Cross-prefix: $CROSS_PREFIX"

export ARCH=arm64
export SUBARCH=arm64
export CC="$CLANG_BIN"
export CROSS_COMPILE="$CROSS_PREFIX"
export CLANG_TRIPLE=aarch64-linux-gnu-
export KCFLAGS="-w"
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

# Make sure kernelsu symlink is in place
if [ ! -e "$KERNEL_DIR/drivers/kernelsu" ]; then
    echo ">> Creating KernelSU symlink..."
    ln -s ../KernelSU/kernel "$KERNEL_DIR/drivers/kernelsu"
fi

echo ">> Generating defconfig..."
make -C "$KERNEL_DIR" ARCH=arm64 SUBARCH=arm64 CC="$CLANG_BIN" CROSS_COMPILE="$CROSS_PREFIX" CLANG_TRIPLE=aarch64-linux-gnu- KCFLAGS="-w -Qunused-arguments" CONFIG_SECTION_MISMATCH_WARN_ONLY=y gta7litewifi_defconfig

echo ">> Compiling kernel with $(nproc) threads..."
make -C "$KERNEL_DIR" ARCH=arm64 SUBARCH=arm64 CC="$CLANG_BIN" CROSS_COMPILE="$CROSS_PREFIX" CLANG_TRIPLE=aarch64-linux-gnu- KCFLAGS="-w -Qunused-arguments" CONFIG_SECTION_MISMATCH_WARN_ONLY=y -j"$(nproc)"

IMAGE="$KERNEL_DIR/arch/arm64/boot/Image"
IMAGE_GZ="$KERNEL_DIR/arch/arm64/boot/Image.gz"
if [ ! -f "$IMAGE_GZ" ] && [ -f "$IMAGE" ]; then
    echo ">> Image.gz not present, compressing Image with gzip..."
    gzip -9 -c "$IMAGE" > "$IMAGE_GZ"
fi

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
