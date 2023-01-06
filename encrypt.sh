parted -s $DISK name 2 CRYPTROOT
partprobe "$DISK"
sleep 1
cryptroot="/dev/disk/by-partlabel/CRYPTROOT"
#Create LUKS Container for Root
echo -n "$ENCRYPTPASS" | cryptsetup luksFormat "$cryptroot" -d -        #Create LUKS Container with ENCRYPTPASS
echo -n "$ENCRYPTPASS" | cryptsetup open "$cryptroot" cryptroot -d -    #Unlocks the LUCKS Container
