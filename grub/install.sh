arch-chroot /mnt /bin/bash grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB
arch-chroot /mnt /bin/bash grub-mkconfig -o /boot/grub/grub.cfg
