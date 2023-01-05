partuuid=$(blkid -s PARTUUID -o value /dev/"$DISK")
arch-chroot /mnt /bin/bash -e <<EOF
	bootctl --path=/boot install
	echo '
title	Arch Linux
linux	/vmlinuz-linux
initrd	/intel-ucode.img
initrd	/initramfs-linux.img
options	root="PARTUUID=$partuuid" rw rootflags=subvol=/@'>> /boot/loader/entries/arch.conf
EOF