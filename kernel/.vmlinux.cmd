cmd_vmlinux := /bin/bash scripts/link-vmlinux.sh aarch64-linux-gnu-ld -EL  -maarch64elf --no-undefined -X -z norelro --fix-cortex-a53-843419  --build-id ;  true
