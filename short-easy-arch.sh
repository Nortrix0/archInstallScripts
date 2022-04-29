#!usr/bin/env -S bash -e
virt_check (){
    hypervisor=$(systemd-detect-virt)
    case $hypervisor in
        kvm )   print "KVM has been detected."
                print "Installing guest tools."
                pacstrap /mnt qemu-guest-agent >/dev/null
                print "Enabling specific services for the guest tools."
                systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
                ;;
        vmware  )   print "VMWare Workstation/ESXi has been detected."
                    print "Installing guest tools."
                    pacstrap /mnt open-vm-tools >/dev/null
                    print "Enabling specific services for the guest tools."
                    systemctl enable vmtoolsd --root=/mnt &>/dev/null
                    systemctl enable vmware-vmblock-fuse --root=/mnt &>/dev/null
                    ;;
        oracle )    print "VirtualBox has been detected."
                    print "Installing guest tools."
                    pacstrap /mnt virtualbox-guest-utils >/dev/null
                    print "Enabling specific services for the guest tools."
                    systemctl enable vboxservice --root=/mnt &>/dev/null
                    ;;
        microsoft ) print "Hyper-V has been detected."
                    print "Installing guest tools."
                    pacstrap /mnt hyperv >/dev/null
                    print "Enabling specific services for the guest tools."
                    systemctl enable hv_fcopy_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_kvp_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_vss_daemon --root=/mnt &>/dev/null
                    ;;
        * ) ;;
    esac
}
#Vars
DISK="/dev/sda"
HOMENAME="ArchAuto"
ROOTPASS="pass"
USERNAME="user"
USERPASS="pass"
#Clear Screen
clear
#Delete Old partition scheme
wipefs -af $DISK &>/dev/null
sgdisk -Zo $DISK &>/dev/null
#Create new partition scheme
parted -s $DISK \
    mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart CRYPTROOT 513MiB 100% \

ESP="/dev/disk/by-partlabel/ESP"
CRYPTROOT="/dev/disk/by-partlabel/CRYPTROOT"
#Inform Kernel of changes
partprobe "$DISK"
#Format ESP as FAT32
mkfs.fat -F 32 $ESP &>/dev/null
#Create LUKS Container for Root
password="password"
echo -n "$password" | cryptsetup luksFormat "$CRYPTROOT" -d -
echo -n "$password" | cryptsetup open "$CRYPTROOT" cryptroot -d -
BTRFS="/dev/mapper/cryptroot"
#Format LUKS Container as BTRFS
mkfs.btrfs $BTRFS &>/dev/null
mount $BTRFS /mnt
#Create BTRFS subvolumes
for volume in @ @home @root @srv @snapshots @var_log @var_pkgs
do
    btrfs su cr /mnt/$volume
done
#Mount new subvolumes
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@ $BTRFS /mnt
mkdir -p /mnt/{home,root,srv,.snapshots,/var/log,/var/cache/pacman/pkg,boot}
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@home $BTRFS /mnt/home
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@root $BTRFS /mnt/root
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@srv $BTRFS /mnt/srv
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@snapshots $BTRFS /mnt/.snapshots
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@var_log $BTRFS /mnt/var/log
mount -o ssd,noatime,compress-force=zstd:3,discard=async,subvol=@var_pkgs $BTRFS /mnt/var/cache/pacman/pkg
#Setup Kernel
kernel="linux"
#Install Microcode
CPU=$(grep vendor_id /proc/cpuinfo)
if [[ $CPU == *"AuthenticAMD"]]; then
    microcode="amd-ucode"
else
    microcode="intel-ucode"
fi
#Check for Virtual Machine
virt_check
#Setup Network
pacstrap /mnt dhcpcd >/dev/null
systemctl enable dhcpcd --root=/mnt &>/dev/null
#Install base system
pacstrap /mnt --needed base $kernel $microcode linux-firmware $kernel-headers btrfs-progs grub grub-btrfs rsync efibootmgr snapper reflector base-devel snap-pac zram-generator >/dev/null
echo "$hostname" > /mnt/etc/hostname
#Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
#Setup Locale
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
#Setup Keyboard
echo "KEYMAP=us" > /mnt/etc/vconsole.conf
#Setup Hosts
cat /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF
#Config mkinitcpio
cat > /mnt/etc/mkinitcpio.conf <<EOF
HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems)
COMPRESSION=(zstd)
EOF
#Setup LUKS2 encryption in grub
UUID=$(blkid -s UUID -o value $CRYPTROOT)
sed -i "s,^GRUB_CMDLINE_LINUX=\"\",GRUB_CMDLINE_LINUX=\"rd.luks.name=$UUID=cryptroot root=$BTRFS\",g" /mnt/etc/default/grub
#Configure System
arch-chroot /mnt /bin/bash -e <<EOF
    ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null
    hwclock --systohc
    locale-gen &>/dev/null
    mkinitcpio -P &>/dev/null
    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots &>/dev/null
    mkdir /.snapshots
    mount -a
    chmod 750 /.snapshots
    grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB &>/dev/null
    grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null
EOF
#Setup User and Root
echo "root:$ROOTPASS" | arch-chroot /mnt chpasswd
arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$USERNAME"
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /mnt/etc/sudoers
echo "$USERNAME:$USERPASS" | arch-chroot /mnt chpasswd
#Boot backup
mkdir /mnt/etc/pacman.d/hooks
cat > /mnt/etc/pacman.d/hooks/50-bootbackup.hook <<EOF
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
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup
EOF
#Configure ZRAM
cat > /mnt/etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = min(ram, 8192)
EOF
#Pacman eye candy
sed -i 's/#Color/Color\nILoveCandy/;s/^^#ParallelDownloads.*$/ParallelDownloads = 10/' /mnt/etc/pacman.conf
for service in reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer  btrfs-scrub@home.timer btrfs-scrub@var-log.timer btrfs-scrub@\\x2esnapshots.timer grub-btrfs.path systemd-oomd
    systemctl enable "$service" --root=/mnt &>/dev/null
done
exit