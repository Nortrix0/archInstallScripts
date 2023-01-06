#Determine Microcode
if [[ $(grep vendor_id /proc/cpuinfo) == *"AuthenticAMD"* ]]; then
    microcode="amd-ucode"
else
    microcode="intel-ucode"
fi
#Install base system
pacstrap /mnt --needed base $KERNEL $microcode vim nano dhcpcd sudo
echo $HOSTNAME > /mnt/etc/hostname
#Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
#Setup Locale
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
#Config mkinitcpio
#echo 'HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems)' >> /mnt/etc/mkinitcpio.conf
#Configure System
ln -sfr /mnt/usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt locale-gen
echo "root:$ROOTPASS" | chpasswd -R /mnt
useradd -mG wheel -p $USERPASS -R /mnt "$USER"
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
#Pacman Color and ParallelDownloads
sed -i 's/#Color/Color/;s/^#ParallelDownloads.*$/ParallelDownloads = 10/' /mnt/etc/pacman.conf
systemctl enable dhcpcd --root=/mnt
