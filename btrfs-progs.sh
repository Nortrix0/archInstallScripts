#Install BTRFS related Packages
pacstrap /mnt btrfs-progs rsync snapper snap-pac
arch-chroot /mnt /bin/bash -e <<EOF
    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots
    mkdir /.snapshots
    mount -a
    chmod 750 /.snapshots
EOF
#Boot backup
mkdir /mnt/etc/pacman.d/hooks
echo '
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = /usr/lib/modules/*/vmlinuz
[Action]
Depends = rsync
Description = Backing up /boot
When = PostTransaction
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup' >> /mnt/etc/pacman.d/hooks/50-bootbackup.hook
#Enable Services
for service in snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer  btrfs-scrub@home.timer btrfs-scrub@var-log.timer btrfs-scrub@\\x2esnapshots.timer
do
    echo "system enable ""$service"" --root=/mnt"
    systemctl enable "$service" --root=/mnt
done