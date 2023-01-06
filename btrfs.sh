btrfs=$([[ $ENCRYPTPASS -eq 0 ]] && echo "/dev/disk/by-partlabel/ROOT" || echo "/dev/mapper/CRYPTROOT")
#Format ROOT as BTRFS
mkfs.btrfs -f $btrfs                #Makes Conatiner BTRFS
mount $btrfs /mnt                   #Mounts BTRFS
#Create BTRFS subvolumes
for volume in @ @home @snapshots @var_log @var_pkgs
do
    btrfs subvolume create /mnt/$volume
done
#Mount only new subvolumes
umount /mnt
mount -o noatime,discard=async,subvol=@ $btrfs /mnt
mkdir -p /mnt/{home,.snapshots,/var/log,/var/cache/pacman/pkg}
mount -o noatime,discard=async,subvol=@home $btrfs /mnt/home
mount -o noatime,discard=async,subvol=@snapshots $btrfs /mnt/.snapshots
mount -o noatime,discard=async,subvol=@var_log $btrfs /mnt/var/log
mount -o noatime,discard=async,subvol=@var_pkgs $btrfs /mnt/var/cache/pacman/pkg
mkdir /mnt/boot
mount $ESP /mnt/boot                #Mounts ESP
