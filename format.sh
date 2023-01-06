#Delete Old partition scheme
wipefs -af $DISK    #Force Wipe All on Disk
sgdisk -Zo $DISK    #Destroys existing GPT/MBR structures and clears out all partition data
#Create new partition scheme
#Doesn't ask for input from user, Creates New disklabel of type GPT, Create new partition Labeled ESP of type fat32 and is 512 MiB in size
#, Sets partition as bootable, Create new partition Labeled ROOT that uses the rest of the drive space
parted -s $DISK mklabel gpt mkpart ESP fat32 1MiB 513MiB set 1 esp on mkpart ROOT 513MiB 100%
partprobe "$DISK"                   #Inform Kernel of changes
sleep 1
esp="/dev/disk/by-partlabel/ESP"
#Format ESP as FAT32
mkfs.fat -F 32 $esp
ROOT="/dev/disk/by-partlabel/ROOT"