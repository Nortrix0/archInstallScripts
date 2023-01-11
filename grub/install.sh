if [[ $ENCRYPTPASS != "" ]]; then
  UUID=$(blkid -s UUID -o value "/dev/disk/by-partlabel/CRYPTROOT")
  sed -i "\,^GRUB_CMDLINE_LINUX=\"\",s,\",&rd.luks.name=$UUID=cryptroot root=$ROOT," /mnt/etc/default/grub
fi
arch-chroot /mnt /bin/bash grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB
arch-chroot /mnt /bin/bash grub-mkconfig -o /boot/grub/grub.cfg
