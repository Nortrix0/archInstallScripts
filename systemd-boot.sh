DISK=$(lsblk -no NAME /dev/disk/by-partlabel/ROOT)
BTRFSPARTUUID=$(blkid -s PARTUUID -o value /dev/"$DISK")
arch-chroot /mnt /bin/bash -e <<EOF
	bootctl --path=/boot install
	echo '
title	Arch Linux
linux	/vmlinuz-linux
initrd	/intel-ucode.img
initrd	/initramfs-linux.img
options	root="PARTUUID=$BTRFSPARTUUID" rw rootflags=subvol=/@'>> /boot/loader/entries/arch.conf
EOF
