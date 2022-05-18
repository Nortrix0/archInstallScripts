#!/usr/bin/env -S bash -e
set -xv
#Vars
read -e -p "Enter the disk to install onto : " -i "/dev/sda" DISK
read -e -p "Enter the Hostname to use : " -i "AutoArch" HOSTNAME
read -r -sp "Enter the to use for root [password]: " rpass
ROOTPASS=${rpass:-"password"}
read -e -p "Enter your username [user]: " -i "user" NEWUSERNAME
read -r -sp "Enter password for $NEWUSERNAME [password]: " upass
USERPASS=${upass:-"password"}
read -e -p "Enter the desired kernel: " -i "linux" KERNEL
#Clear Screen
clear
#Delete Old partition scheme
wipefs -af $DISK    #Force Wipe All on Disk
sgdisk -Zo $DISK    #Destroys existing GPT/MBR structures and clears out all partition data
#Create new partition scheme
#Doesn't ask for input from user, Creates New disklabel of type GPT, Create new partition Labeled ESP of type fat32 and is 512 MiB in size
#, Sets partition as bootable, Create new partition Labelel CRYPTROOT that uses the rest of the drive space
parted -s $DISK mklabel gpt mkpart ESP fat32 1MiB 513MiB set 1 esp on mkpart ROOT 513MiB 100%
partprobe "$DISK"                   #Inform Kernel of changes
sleep 1
ESP="/dev/disk/by-partlabel/ESP"
BTRFS="/dev/disk/by-partlabel/ROOT"
#Format ESP as FAT32
mkfs.fat -F 32 $ESP
#Format ROOT as BTRFS
mkfs.btrfs $BTRFS                   #Makes Conatiner BTRFS
mount $BTRFS /mnt                   #Mounts BTRFS
#Create BTRFS subvolumes
for volume in @ @home @root @srv @snapshots @var_log @var_pkgs
do
    btrfs subvolume create /mnt/$volume
done
#Mount only new subvolumes
umount /mnt
mount -o noatime,discard=async,subvol=@ $BTRFS /mnt
mkdir -p /mnt/{home,root,srv,.snapshots,/var/log,/var/cache/pacman/pkg,boot}
mount -o noatime,discard=async,subvol=@home $BTRFS /mnt/home
mount -o noatime,discard=async,subvol=@root $BTRFS /mnt/root
mount -o noatime,discard=async,subvol=@srv $BTRFS /mnt/srv
mount -o noatime,discard=async,subvol=@snapshots $BTRFS /mnt/.snapshots
mount -o noatime,discard=async,subvol=@var_log $BTRFS /mnt/var/log
mount -o noatime,discard=async,subvol=@var_pkgs $BTRFS /mnt/var/cache/pacman/pkg
mount $ESP /mnt/boot                #Mounts ESP
#Install Microcode
CPU=$(grep vendor_id /proc/cpuinfo)
if [[ $CPU == *"AuthenticAMD"* ]]; then
    microcode="amd-ucode"
else
    microcode="intel-ucode"
fi
#Install base system
pacman -Sy archlinux-keyring --noconfirm
pacstrap /mnt --needed base $KERNEL $microcode linux-firmware $KERNEL-headers btrfs-progs grub grub-btrfs rsync efibootmgr snapper reflector base-devel snap-pac zram-generator vim nano dhcpcd
echo "$HOSTNAME" > /mnt/etc/hostname
#Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
#Setup Locale
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
#Setup Keyboard
echo "KEYMAP=us" > /mnt/etc/vconsole.conf
#Setup Hosts
echo '
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname' >>/mnt/etc/hosts
#Config mkinitcpio //CHANGE TO ECHO
echo '
HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems)
COMPRESSION=(zstd)' >> /mnt/etc/mkinitcpio.conf
#Configure System //MKDIR etc/localtime?
arch-chroot /mnt /bin/bash -e <<EOF
    ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime
    hwclock --systohc
    locale-gen
    mkinitcpio -P
    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots
    mkdir /.snapshots
    mount -a
    chmod 750 /.snapshots
    grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "root:$ROOTPASS" | chpasswd
    useradd -m -G wheel -s /bin/bash "$NEWUSERNAME"
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    echo "$NEWUSERNAME:$USERPASS" | chpasswd
EOF
#Boot backup
mkdir /mnt/etc/pacman.d/hooks
echo '
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = /usr/lib/modules/*/vmlinuz
[Action]
Depends = rsync
Description = Backing up /boot
When = PostTransaction
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup' >> /mnt/etc/pacman.d/hooks/50-bootbackup.hook
#Configure ZRAM
echo '
[zram0]
zram-size = min(ram, 8192)' >> /mnt/etc/systemd/zram-generator.conf
#Pacman Color and ParallelDownloads
sed -i 's/#Color/Color/;s/^#ParallelDownloads.*$/ParallelDownloads = 10/' /mnt/etc/pacman.conf
for service in reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer  btrfs-scrub@home.timer btrfs-scrub@var-log.timer btrfs-scrub@\\x2esnapshots.timer grub-btrfs.path systemd-oomd dhcpcd
do
    echo "system enable ""$service"" --root=/mnt"
    systemctl enable "$service" --root=/mnt
done