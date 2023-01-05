root=$(lsblk -no NAME /dev/disk/by-partlabel/ROOT)
partuuid=$(blkid -s PARTUUID -o value /dev/"$root")
arch-chroot /mnt /bin/bash -e <<EOF
	bootctl --path=/boot install
	echo '
title	Arch Linux
linux	/vmlinuz-linux
initrd	/intel-ucode.img
initrd	/initramfs-linux.img
options	root="PARTUUID=$partuuid" rw'>> /boot/loader/entries/arch.conf
if [[ $FILESYS -eq "btrfs" ]]; then
	echo ' rootflags=subvol=/@'  >> /boot/loader/entries/arch.conf
fi
EOF
