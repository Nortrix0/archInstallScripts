arch-chroot /mnt /bin/bash -e <<EOF
	bootctl --parth=/boot install
	echo '
title	Arch Linux
linux	/vmlinuz-linux
initrd	/intel-ucode.img
initrd	/initramfs-linux.img
options	root="LABEL=ROOT" rw'>> /boot/loader/entries/arch.conf
EOF
