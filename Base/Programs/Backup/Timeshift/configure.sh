UUID=$(blkid -s UUID -o value $ROOT)
sed "s|DEVICEUUID|$UUID|" ./Programs/Backup/Timeshift/timeshift.json > /mnt/etc/timeshift/timeshift.json