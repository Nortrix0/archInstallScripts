#!/usr/bin/env -S bash -e
set -xv
#Vars
read -e -p "Enter the disk to install onto : " -i "/dev/sda" DISK
read -e -p "Enter the Hostname to use : " -i "AutoArch" HOSTNAME
read -r -sp "Enter the password for root [password]: " rpass
ROOTPASS=${rpass:-"password"}
read -e -p "Enter your username [user]: " -i "user" NEWUSERNAME
read -r -sp "Enter password for $NEWUSERNAME [password]: " upass
USERPASS=${upass:-"password"}
read -e -p "Enter the desired kernel: " -i "linux" KERNEL
read -e -p "Enter the desired file system [ext4/btrfs]: " -i "ext4" FILESYSTEM
#Clear Screen
clear
#Obtain latest Keyring
pacman -Sy archlinux-keyring --noconfirm
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
./"$FILESYSTEM".sh
mkdir /mnt/boot
mount $ESP /mnt/boot                #Mounts ESP
#Install Microcode
CPU=$(grep vendor_id /proc/cpuinfo)
if [[ $CPU == *"AuthenticAMD"* ]]; then
    microcode="amd-ucode"
else
    microcode="intel-ucode"
fi
#Install base system
pacstrap /mnt --needed base $KERNEL $microcode vim nano dhcpcd sudo
echo "$HOSTNAME" > /mnt/etc/hostname
#Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
#Setup Locale
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
#Config mkinitcpio
echo 'HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems)' >> /mnt/etc/mkinitcpio.conf
#Configure System
arch-chroot /mnt /bin/bash -e <<EOF
    ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime
    hwclock --systohc
    locale-gen
    mkinitcpio -P
    echo "root:$ROOTPASS" | chpasswd
    useradd -m -G wheel -s /bin/bash "$NEWUSERNAME"
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    echo "$NEWUSERNAME:$USERPASS" | chpasswd
EOF
#Pacman Color and ParallelDownloads
sed -i 's/#Color/Color/;s/^#ParallelDownloads.*$/ParallelDownloads = 10/' /mnt/etc/pacman.conf
systemctl enable dhcpcd --root=/mnt
