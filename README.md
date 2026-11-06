# Samsung Galaxy Tab A7 Lite (SM-T220) Custom Kernel with KernelSU

This repository contains the complete modified kernel source code, KernelSU integration, custom kernel driver, and automated build scripts for the **Samsung Galaxy Tab A7 Lite Wi-Fi (SM-T220 / gta7litewifi)** running MediaTek MT8768 / MT6765 SoC.

---

## 🚀 How to Build on GitHub (GitHub Actions CI/CD)

This repository includes a pre-configured GitHub Actions workflow (`.github/workflows/build_kernel.yml`) that can automatically compile the kernel on GitHub's cloud runners for free:

1. **Upload / Push this repository to your GitHub account**:
   ```bash
   git init
   git add .
   git commit -m "Initial commit of SM-T220 KernelSU"
   git branch -M main
   git remote add origin https://github.com/<your-username>/<your-repo-name>.git
   git push -u origin main
   ```
2. **Run the Build on GitHub**:
   * Navigate to the **Actions** tab on your GitHub repository page.
   * Under workflows, select **"Build SM-T220 Custom Kernel & Driver"**.
   * Click **Run workflow** -> **Run workflow**.
3. **Download the Flashable Boot Image**:
   * When the run completes (takes ~5–10 mins), scroll down to the **Artifacts** section at the bottom of the workflow page.
   * Download `SM-T220-KernelSU-CustomKernel.zip`. Inside is the flashable `boot.img`, the driver `.ko`, and the KernelSU APK!

---

## 💻 How to Build Locally (Ubuntu / WSL)

If you want to build locally on your own machine:

1. **Install required build tools**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y bc bison flex libssl-dev python3 make gcc-aarch64-linux-gnu libelf-dev curl tar gzip libncurses5-dev
   ```
2. **Execute the automated build script**:
   ```bash
   ./build.sh
   ```
   * The script will automatically download the matching Google AOSP Clang (`clang-r383902`) and GCC 4.9 cross-compilers if not already present.
   * It compiles the kernel using `gta7litewifi_defconfig`.
   * It repacks `Image.gz`, DTB, and Ramdisk into a 32 MB flashable Samsung `boot.img`.

---

## 📂 Repository Contents

* `kernel/`: Full Linux 4.19 kernel source tree with:
  * Official KernelSU integration (`drivers/kernelsu` -> `../KernelSU/kernel`).
  * Custom SELinux policy patches allowing `ksu` and `su` domains full root capabilities (`rules.c`).
  * Bypass patches for Samsung Defex and module vermagic/CRC verification (`kernel/module.c`).
  * Pre-configured defconfig (`arch/arm64/configs/gta7litewifi_defconfig`).
* `driver/`: Custom stealth kernel driver:
  * `5.10_A12.ko` & `5.10_12A.ko`: Stealth driver with device node `/dev/5.10_A12` and permissions `0666`.
  * `load_driver.sh`: Automated driver loading script with SELinux domain labels.
* `stock/`: Extracted stock kernel components (`stock_kernel.gz`, `stock_ramdisk.cpio.gz`, `stock_dtb.dtb`, `boot.img`).
* `boot.img`: Compiled, patched 32 MB boot image ready for flashing.
* `build.sh`: End-to-end automated compilation script.
* `repack_boot.py`: Android Header v2 32MB boot image repacker with Samsung trailer.
* `.github/workflows/build_kernel.yml`: GitHub Actions automated cloud build workflow.
* `setup_clean_kernel.py`: Automated Python script to apply all patches and hooks to a fresh Samsung kernel tree.

---

## 📲 Flashing Instructions

1. **Fastboot**:
   ```bash
   fastboot flash boot boot.img
   fastboot reboot
   ```
2. **MT Manager / Root / TWRP**:
   * Flash `boot.img` directly to the `boot` partition.
   * Install `KernelSU_v3.3.1_32680-release.apk`.
   * Reboot device.
