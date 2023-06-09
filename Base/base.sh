#Delete Old partition scheme
wipefs -af $DISK    #Force Wipe All on Disk
sgdisk -Zo $DISK    #Destroys existing GPT/MBR structures and clears out all partition data
#Create new partition scheme
#Doesn't ask for input from user, Creates New disklabel of type GPT, Create new partition Labeled ESP of type fat32 and is 512 MiB in size
#, Sets partition as bootable, Create new partition Labeled ROOT that uses the rest of the drive space
parted -s $DISK mklabel gpt mkpart ESP fat32 1MiB 513MiB set 1 esp on mkpart ROOT 513MiB 100%
partprobe "$DISK"                   #Inform Kernel of changes
sleep 1
ESP="/dev/disk/by-partlabel/ESP"
#Format ESP as FAT32
mkfs.fat -F 32 $ESP
ROOT="/dev/disk/by-partlabel/ROOT"
#Determine Microcode
microcode=$([[ $(grep vendor_id /proc/cpuinfo) == *"AuthenticAMD"* ]] && echo "amd-ucode" || echo "intel-ucode")
sed -i "s|microcode|$microcode|" ./Base/packages.txt
#Install base system
pacstrap /mnt --needed - < ./Base/packages.txt
echo $HOSTNAME > /mnt/etc/hostname
#Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
#Setup Locale
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
#Config mkinitcpio
echo 'HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems)' >> /mnt/etc/mkinitcpio.conf
#Configure System
ln -sfr /mnt/usr/share/zoneinfo/America/Chicago /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt locale-gen
echo "root:$ROOTPASS" | chpasswd -R /mnt
useradd -mG wheel -R /mnt "$USER"
echo "$USER:$USERPASS" | chpasswd -R /mnt
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
#Pacman Color and ParallelDownloads
sed -i 's/#Color/Color/;s/^#ParallelDownloads.*$/ParallelDownloads = 10/' /mnt/etc/pacman.conf
while read s; do
	systemctl enable $s --root=/mnt
done <./Base/services.txt
