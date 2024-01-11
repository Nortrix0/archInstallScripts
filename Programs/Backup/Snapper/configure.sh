arch-chroot /mnt snapper --no-dbus -c root create-config /
chgrp wheel /mnt/.snapshots
sed -i 's/ALLOW_USERS=.*$/ALLOW_USERS="'"$USER"'"/; s/TIMELINE_CREATE=.*$/TIMELINE_CREATE="no"/; s/MONTHLY=.*$/MONTHLY="0"/; s/YEARLY=.*$/YEARLY="0"/' /mnt/etc/snapper/configs/root