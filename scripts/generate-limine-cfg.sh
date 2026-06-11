#!/bin/bash
# Generate Limine bootloader config for the Gentoo ISO

KVER="${1:-$(ls -1 /lib/modules/ | sort -V | tail -1)}"
OUTPUT="${2:-/iso-root/limine.cfg}"

NVIDIA_CMDLINE="nvidia_drm.modeset=1 nvidia.NVreg_DynamicPowerManagement=0x02 nvidia.NVreg_PreserveVideoMemoryAllocations=1"

cat > "$OUTPUT" << LIMINECFG
TIMEOUT=30

/Gentoo Linux (Desktop)
    PROTOCOL=linux
    KERNEL_PATH=boot:///vmlinuz-${KVER}
    CMDLINE=root=UUID=1234 ro quiet rd.vconsole.keymap=uk ${NVIDIA_CMDLINE}
    MODULE_PATH=boot:///amd-uc.img
    MODULE_PATH=boot:///initramfs.img

/Gentoo Linux (Rescue Mode)
    PROTOCOL=linux
    KERNEL_PATH=boot:///vmlinuz-${KVER}
    CMDLINE=root=UUID=1234 ro single rd.shell rd.debug ${NVIDIA_CMDLINE}
    MODULE_PATH=boot:///amd-uc.img
    MODULE_PATH=boot:///initramfs.img
LIMINECFG
