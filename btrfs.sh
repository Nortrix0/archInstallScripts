#Format ROOT as BTRFS
mkfs.btrfs -f $ROOT                #Makes Conatiner BTRFS
mount $ROOT /mnt                   #Mounts BTRFS
#Create BTRFS subvolumes
for volume in @ @home @snapshots @var_log @var_pkgs
do
    btrfs subvolume create /mnt/$volume
done
#Mount only new subvolumes
umount /mnt
mount -o noatime,discard=async,subvol=@ $ROOT /mnt
mkdir -p /mnt/{home,.snapshots,/var/log,/var/cache/pacman/pkg}
mount -o noatime,discard=async,subvol=@home $ROOT /mnt/home
mount -o noatime,discard=async,subvol=@snapshots $ROOT /mnt/.snapshots
mount -o noatime,discard=async,subvol=@var_log $ROOT /mnt/var/log
mount -o noatime,discard=async,subvol=@var_pkgs $ROOT /mnt/var/cache/pacman/pkg
mkdir /mnt/boot
mount $ESP /mnt/boot                #Mounts ESP
