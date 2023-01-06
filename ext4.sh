mkfs.ext4 -F "/dev/disk/by-partlabel/ROOT"             #Makes Conatiner EXT4
mount "/dev/disk/by-partlabel/ROOT" /mnt               #Mounts EXT4
mkdir /mnt/boot
mount $ESP /mnt/boot                                   #Mounts ESP
