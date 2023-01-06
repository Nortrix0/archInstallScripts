parted -s $DISK name 2 CRYPTROOT
partprobe "$DISK"
sleep 1
ROOT="/dev/disk/by-partlabel/CRYPTROOT"
#Create LUKS Container for Root
echo -n "$ENCRYPTPASS" | cryptsetup luksFormat "$ROOT" -d -        #Create LUKS Container with ENCRYPTPASS
echo -n "$ENCRYPTPASS" | cryptsetup open "$ROOT" cryptroot -d -    #Unlocks the LUCKS Container
