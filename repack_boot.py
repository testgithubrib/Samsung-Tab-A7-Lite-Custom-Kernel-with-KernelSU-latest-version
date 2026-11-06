#!/usr/bin/env python3
import os
import sys
import struct
import hashlib

def repack_boot_v2(kernel_path, ramdisk_path, dtb_path, out_path,
                   cmdline_str="bootopt=64S3,32N2,64N2 androidboot.tag=TabA7lite_Huaqin_BSP_20210408174009 loop.max_part=7",
                   name_str="SRPUA15A010", target_size=33554432):
    if not os.path.exists(kernel_path):
        sys.exit(f"Error: Kernel {kernel_path} not found")
    if not os.path.exists(ramdisk_path):
        sys.exit(f"Error: Ramdisk {ramdisk_path} not found")
    if not os.path.exists(dtb_path):
        sys.exit(f"Error: DTB {dtb_path} not found")

    with open(kernel_path, 'rb') as f:
        kernel = f.read()
    with open(ramdisk_path, 'rb') as f:
        ramdisk = f.read()
    with open(dtb_path, 'rb') as f:
        dtb = f.read()

    page_sz = 2048
    k_sz = len(kernel)
    r_sz = len(ramdisk)
    d_sz = len(dtb)

    def pad(data, sz):
        rem = len(data) % sz
        return data if rem == 0 else data + b'\x00' * (sz - rem)

    # SHA1 over kernel + ramdisk + second(0) + rec_dtbo(0) + dtb
    h = hashlib.sha1()
    h.update(kernel)
    h.update(struct.pack('<I', k_sz))
    h.update(ramdisk)
    h.update(struct.pack('<I', r_sz))
    h.update(b'')
    h.update(struct.pack('<I', 0))
    h.update(b'')
    h.update(struct.pack('<I', 0))
    h.update(dtb)
    h.update(struct.pack('<I', d_sz))
    id_hash = h.digest() + b'\x00' * (32 - len(h.digest()))

    cmdline_bytes = cmdline_str.encode('utf-8')[:512].ljust(512, b'\x00')
    extra_cmdline = b''.ljust(1024, b'\x00')
    name_bytes = name_str.encode('utf-8')[:16].ljust(16, b'\x00')

    fmt = '<8s8I2I16s512s32s1024sIQIIQ'
    hdr = struct.pack(fmt,
        b'ANDROID!',
        k_sz, 0x40008000,
        r_sz, 0x44000000,
        0, 0x40000000,
        0x40000100, page_sz,
        2,          # header version 2
        0x0c000000, # os_version (Android 12 base)
        name_bytes,
        cmdline_bytes,
        id_hash,
        extra_cmdline,
        0, 0,       # recovery dtbo size & offset
        struct.calcsize(fmt), # header_size
        d_sz, 0x40000100      # dtb size & addr
    )

    hdr_padded = pad(hdr, page_sz)
    kernel_padded = pad(kernel, page_sz)
    ramdisk_padded = pad(ramdisk, page_sz)
    dtb_padded = pad(dtb, page_sz)
    trailer = b'SEANDROIDENFORCE' + b'\x00' * 48

    payload = hdr_padded + kernel_padded + ramdisk_padded + dtb_padded + trailer
    if len(payload) > target_size:
        sys.exit(f"Error: payload size {len(payload)} exceeds target size {target_size}")

    padded_final = payload + b'\x00' * (target_size - len(payload))

    with open(out_path, 'wb') as f:
        f.write(padded_final)

    print(f"[OK] Repacked boot image created: {out_path} ({len(padded_final)} bytes)")

if __name__ == '__main__':
    base_dir = os.path.dirname(os.path.abspath(__file__))
    k_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(base_dir, 'kernel/arch/arm64/boot/Image.gz')
    r_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(base_dir, 'stock/stock_ramdisk.cpio.gz')
    d_path = sys.argv[3] if len(sys.argv) > 3 else os.path.join(base_dir, 'stock/stock_dtb.dtb')
    o_path = sys.argv[4] if len(sys.argv) > 4 else os.path.join(base_dir, 'boot.img')

    repack_boot_v2(k_path, r_path, d_path, o_path)
