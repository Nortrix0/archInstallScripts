pacstrap /mnt --needed grub grub-btrfs
arch-chroot /mnt /bin/bash -e <<EOF
	grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB
	grub-mkconfig -o /boot/grub/grub.cfg
EOF
systemctl enable "grub-btrfsd" --root=/mnt
