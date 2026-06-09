#!/bin/bash
# OpenRC-friendly initramfs generator with udev hotfix

kver="$1"
output="$2"

[[ -n "$kver" ]] || { echo "Usage: $0 <kernel_version> <output>"; exit 1; }
[[ -n "$output" ]] || output="/boot/efi/initramfs.img"

# Hotfix: temporarily hide udev binary to avoid systemd library errors
if [[ -x /sbin/udevadm ]]; then
    mv /sbin/udevadm /sbin/udevadm.bak
    restore_udev=true
fi

# Generate initramfs
dracut \
    --kver "$kver" \
    --zstd \
    --no-hostonly \
    --ro-mnt \
    --add "bash crypt crypt-gpg" \
    --force "$output"

# Restore udev binary
if [[ "$restore_udev" == true ]]; then
    mv /sbin/udevadm.bak /sbin/udevadm
fi

echo "Initramfs for kernel $kver written to $output successfully."
