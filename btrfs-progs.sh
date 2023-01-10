#Install BTRFS related Packages
pacstrap /mnt btrfs-progs rsync snapper snap-pac
#Enable Services
for service in snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@var-log.timer btrfs-scrub@\\x2esnapshots.timer
do
    echo "system enable ""$service"" --root=/mnt"
    systemctl enable "$service" --root=/mnt
done
