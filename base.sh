#!/usr/bin/env -S bash -e
#Clear Screen
clear
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
. ./"$FILESYSTEM".sh
mkdir /mnt/boot
mount $esp /mnt/boot                #Mounts ESP
#Install Microcode
cpu=$(grep vendor_id /proc/cpuinfo)
if [[ $cpu == *"AuthenticAMD"* ]]; then
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
    useradd -m -G wheel -s /bin/bash "$USER"
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    echo "$USER:$USERPASS" | chpasswd
EOF
#Pacman Color and ParallelDownloads
sed -i 's/#Color/Color/;s/^#ParallelDownloads.*$/ParallelDownloads = 10/' /mnt/etc/pacman.conf
systemctl enable dhcpcd --root=/mnt
