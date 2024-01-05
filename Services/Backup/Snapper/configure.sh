arch-chroot /mnt snapper --no-dbus -c root create-config /
arch-chroot /mnt chown :wheel /.snapshots
sed -i 's/ALLOW_USERS=.*$/ALLOW_USERS="'"$USER"'"/; s/MONTHLY=.*$/MONTHLY="0"/; s/YEARLY=.*$/YEARLY="0"/' /mnt/etc/snapper/configs/root