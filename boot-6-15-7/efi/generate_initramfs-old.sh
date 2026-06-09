#!/bin/bash
kver="$1"
output="$2" # At setup time, this was "/boot/efi/initramfs.img"
[[ -n "$kver" ]] || { echo "usage $0 <kernel_version> <output>" >&2; exit 1; }
dracut \
	--kver          "$kver" \
	--zstd \
	--no-hostonly \
	--ro-mnt \
	--add           "bash crypt crypt-gpg" \
	 \
	--force \
	"$output"
