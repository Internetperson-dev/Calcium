#!/bin/bash
# This is the command that was used to create the efibootmgr entry when the
# system was installed using gentoo-install.

# This is for SDA
#efibootmgr --verbose --create --disk "/dev/sda" --part "1" --label "gentoo" --loader '\vmlinuz.efi' --unicode 'initrd=\initramfs.img'" rd.vconsole.keymap=uk rd.luks.uuid=e7af3fdd-651a-472a-b3c5-b94bb515ad41 root=UUID=f1f4c287-7056-4e9a-acc7-c33853f8eb15"

efibootmgr --verbose --create --disk "/dev/sda" --part "1" --label "gentoo" --loader '\EFI\gentoo\vmlinuz.efi' --unicode 'initrd=\EFI\gentoo\initramfs.img rd.vconsole.keymap=uk rd.luks.uuid=e7af3fdd-651a-472a-b3c5-b94bb515ad41 root=UUID=f1f4c287-7056-4e9a-acc7-c33853f8eb15'
