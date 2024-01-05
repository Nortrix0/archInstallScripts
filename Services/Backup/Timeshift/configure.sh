UUID=$(blkid -s UUID -o value $ROOT)
sed -i "s|DEVICEUUID|$UUID|" ./Services/Backup/Timeshift/timeshift.json
cp ./Services/Backup/Timeshift /mnt/etc/timeshift/timeshift.json