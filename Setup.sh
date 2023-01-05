clear
#Set ParallelDownloads on archIso to help speed up install
sed -i 's|^#ParallelDownloads.*$|ParallelDownloads = 10|' /etc/pacman.conf
#Obtain latest Keyring
pacman -Sy dialog --noconfirm
DISK=$(dialog --nocancel --menu "Select Disk" 0 0 5 $(lsblk -rnpSo NAME,SIZE) 3>&1 1>&2 2>&3 3>&-)
KERNEL=$(dialog --nocancel --radiolist "Select Kernel" 0 0 2 linux Stable on linux-hardened Hardened off linux-lts Longterm off linux-zen Zen off 3>&1 1>&2 2>&3 3>&-)
HOSTNAME=$(dialog --nocancel --inputbox "Enter Hostname" 0 0 "ArchAuto" 3>&1 1>&2 2>&3 3>&-)
ROOTPASS=$(dialog --nocancel --passwordbox "Enter Pasword for Root" 0 0 3>&1 1>&2 2>&3 3>&-)
USER=$(dialog --nocancel --inputbox "Enter Username" 0 0 "user" 3>&1 1>&2 2>&3 3>&-)
while ! [[ $USER =~ ^[a-z_][a-z0-9_-]{0,30}[$]?$ ]] do
	USER=$(dialog --nocancel --inputbox "$USER Invalid Must Be At Most 32 Characters And lowercase" 0 0 $(echo "$USER" | tr '[:upper:]' '[:lower:]') 3>&1 1>&2 2>&3 3>&-)
done
USERPASS=$(dialog --nocancel --passwordbox "Enter Pasword for $USER" 0 0 3>&1 1>&2 2>&3 3>&-)
FILESYS=$(dialog --nocancel --radiolist "Select Filesystem" 0 0 0 etx4 "" on btrfs "" off 3>&1 1>&2 2>&3 3>&-)
BOOTLOADER=$(dialog --nocancel --radiolist "Select Bootloader" 0 0 0 systemd-boot "" on grub "" off 3>&1 1>&2 2>&3 3>&-)
GRAPHICAL=$(dialog --defaultno --yesno "Do You Want Console Only?" 0 0 3>&1 1>&2 2>&3 3>&-)
if [ $GRAPHICAL == "1"]
	CONFIGS=$(dialog --yesno "Do You Want Customized KDE Configs?" 0 0 3>&1 1>&2 2>&3 3>&-)
fi
. ./base.sh
. ./"$BOOTLOADER".sh
if [ $GRAPHICAL == "1"]
	. ./kde-install.sh
fi
ADVANCED=$(dialog --no-label "Manually Edit" --yes-label "Reboot" --yesno "What would you like to do?" 0 0 3>&1 1>&2 2>&3 3>&-)
if [ $ADVANCED == "0"]
	reboot
else
	clear
fi
