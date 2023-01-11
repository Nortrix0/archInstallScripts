mkfs.ext4 -F "$ROOT"             #Makes Conatiner EXT4
mount "$ROOT" /mnt               #Mounts EXT4
mkdir /mnt/boot
mount $ESP /mnt/boot                                   #Mounts ESP
