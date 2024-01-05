#Delete Old partition scheme
wipefs -af $DISK    #Force Wipe All on Disk
sgdisk -Zo $DISK    #Destroys existing GPT/MBR structures and clears out all partition data
#Create new partition scheme
#Doesn't ask for input from user, Creates New disklabel of type GPT, Create new partition Labeled ESP of type fat32 and is 512 MiB in size
#, Sets partition as bootable, Create new partition Labeled ROOT that uses the rest of the drive space
parted -s $DISK mklabel gpt mkpart ESP fat32 0% 513MiB set 1 esp on mkpart ROOT 513MiB 100%
partprobe "$DISK"                   #Inform Kernel of changes
sleep 1
ESP="/dev/disk/by-partlabel/ESP"
#Format ESP as FAT32
mkfs.fat -F 32 $ESP
ROOT="/dev/disk/by-partlabel/ROOT"
#Format ROOT as BTRFS
mkfs.btrfs -f $ROOT                #Makes Conatiner BTRFS
mount $ROOT /mnt                   #Mounts BTRFS
#Create BTRFS subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var_log
#Mount only new subvolumes
umount /mnt
mount -o noatime,discard=async,subvol=@ $ROOT /mnt
mkdir -p /mnt/{home,/var/log}
mount -o noatime,discard=async,subvol=@home $ROOT /mnt/home
mount -o noatime,discard=async,subvol=@var_log $ROOT /mnt/var/log
#mount -o noatime,discard=async,subvol=@var_pkgs $ROOT /mnt/var/cache/pacman/pkg
mkdir /mnt/boot
mount $ESP /mnt/boot                #Mounts ESP
#Install base system
until pacstrap /mnt --needed - < ./install_packages.txt; do
	echo "Failed Getting Packages, will try again in 5 Seconds.  Press Control+C to cancel"
	sleep 5
done
echo $HOSTNAME > /mnt/etc/hostname
#Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
#Setup Locale
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
#Config mkinitcpio
sed -i 's/^HOOKS=.*$/HOOKS=(base systemd autodetect modconf kms block keyboard sd-vconsole lvm2 filesystems fsck grub-btrfs-overlayfs)/' >> /mnt/etc/mkinitcpio.conf
#Configure System
ln -sfr /mnt/usr/share/zoneinfo/America/Chicago /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt locale-gen
if [[ $USEROOT == "Disabled" ]]; then
	arch-chroot /mnt usermod -p '!' root
else
	echo "root:$ROOTPASS" | chpasswd -R /mnt
fi
useradd -mG wheel -R /mnt "$USER"
echo "$USER:$USERPASS" | chpasswd -R /mnt
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
#Pacman Color and ParallelDownloads
sed -i 's/#Color/Color/;s/^#ParallelDownloads.*$/ParallelDownloads = 10/' /mnt/etc/pacman.conf
. ./Services/Backup/$BACKUP/configure.sh
while read s; do
	systemctl enable $s --root=/mnt
done <./install_services.txt
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot /mnt timedatectl set-ntp true
arch-chroot /mnt ln -rsf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
 ./Services/Backup/$BACKUP/create.sh | arch-chroot /mnt
