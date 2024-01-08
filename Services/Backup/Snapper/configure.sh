snapper --no-dbus -r /mnt -c root create-config /
chgrp -R wheel /mnt/.snapshots
sed -i 's/ALLOW_USERS=.*$/ALLOW_USERS="'"$USER"'"/; s/MONTHLY=.*$/MONTHLY="0"/; s/YEARLY=.*$/YEARLY="0"/' /mnt/etc/snapper/configs/root