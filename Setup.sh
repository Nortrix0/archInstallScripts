cd "${0%/*}"
clear
#Set ParallelDownloads on ArchIso to help speed up install
sed -i 's|^#ParallelDownloads.*$|ParallelDownloads = 10|' /etc/pacman.conf
pacman -Sy dialog --noconfirm
DISK=$(dialog --nocancel --menu "Select Disk" 0 0 5 $(lsblk -rnpSo NAME,SIZE) 3>&1 1>&2 2>&3 3>&-)
KERNEL=$(dialog --nocancel --radiolist "Select Kernel" 0 0 2 linux Stable on linux-hardened Hardened off linux-lts Longterm off linux-zen Zen off 3>&1 1>&2 2>&3 3>&-)
HOSTNAME=$(dialog --nocancel --inputbox "Enter Hostname" 0 0 "ArchAuto" 3>&1 1>&2 2>&3 3>&-)
while ! [[ $USER =~ ^[a-z_][a-z0-9_-]{0,30}[$]?$ ]]; do
	HOSTNAME=$(dialog --nocancel --inputbox "$HOSTNAME Invalid Must Be At Most 63 Characters And Only Contain A-Z and - but can not start with -" 0 0 "ArchAuto" 3>&1 1>&2 2>&3 3>&-)
done
ROOTPASS=$(dialog --nocancel --passwordbox "Enter Pasword for Root" 0 0 3>&1 1>&2 2>&3 3>&-)
USER=$(dialog --nocancel --inputbox "Enter Username" 0 0 "user" 3>&1 1>&2 2>&3 3>&-)
while ! [[ $USER =~ ^[a-z_][a-z0-9_-]{0,30}[$]?$ ]]; do
	USER=$(dialog --nocancel --inputbox "$USER Invalid Must Be At Most 32 Characters And lowercase" 0 0 $(echo "$USER" | tr '[:upper:]' '[:lower:]') 3>&1 1>&2 2>&3 3>&-)
done
USERPASS=$(dialog --nocancel --passwordbox "Enter Pasword for $USER" 0 0 3>&1 1>&2 2>&3 3>&-)
FILESYS=$(dialog --nocancel --radiolist "Select Filesystem" 0 0 0 btrfs "" on ext4 "" off 3>&1 1>&2 2>&3 3>&-)
ENCRYPTPASS=$(dialog --nocancel --passwordbox "Enter Password for Encryption, Leave Blank If You Do Not Want Encryption" 0 0 3>&1 1>&2 2>&3 3>&-)
BOOTLOADER=$(dialog --nocancel --radiolist "Select Bootloader" 0 0 0 systemd-boot "" on grub "" off 3>&1 1>&2 2>&3 3>&-)
DESKTOP=$(dialog --nocancel --radiolist "Which Desktop Do You Want?" 0 0 0 KDE "" on Console "" off 3>&1 1>&2 2>&3 3>&-)
if [[ $DESKTOP == "KDE" ]]; then
	CONFIGS=$($(dialog --yesno "Do You Want Customized KDE Configs?" 0 0 3>&1 1>&2 2>&3 3>&-) && echo "Yes" || echo "No")
fi
. ./format.sh
if [[ $ENCRYPTPASS == "" ]]; then
	. ./encrypt.sh
fi
. ./"$FILESYS".sh
. ./base.sh
if [[ $FILESYS == "btrfs" ]]; then
	. ./btrfs-progs.sh
fi
. ./"$BOOTLOADER".sh
if [[ $DESKTOP == "KDE" ]]; then
	. ./kde-install.sh
fi
ADVANCED=$(dialog --nocancel --menu "What would you like to do?" 0 0 0 "Reboot" "" "Manually Edit" "" 3>&1 1>&2 2>&3 3>&-)
if [[ $ADVANCED == "Reboot" ]]; then
	reboot
else
	clear
fi
