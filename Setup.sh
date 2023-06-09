cd "${0%/*}"
clear
#Set ParallelDownloads on ArchIso to help speed up install
sed -i 's|^#ParallelDownloads.*$|ParallelDownloads = 10|' /etc/pacman.conf
pacman -Sy dialog --noconfirm
DISK=$(dialog --nocancel --menu "Select Disk" 0 0 5 $(lsblk -rnpSo NAME,SIZE) 3>&1 1>&2 2>&3 3>&-)
kernel=$(dialog --nocancel --radiolist "Select Kernel" 0 0 2 linux Stable on linux-hardened Hardened off linux-lts Longterm off linux-zen Zen off 3>&1 1>&2 2>&3 3>&-)
sed -i "s|KERNEL|$kernel|" ./Base/packages.txt
HOSTNAME=$(dialog --nocancel --inputbox "Enter Hostname" 0 0 "ArchAuto" 3>&1 1>&2 2>&3 3>&-)
while ! [[ $USER =~ ^[a-z_][a-z0-9_-]{0,30}[$]?$ ]]; do
	HOSTNAME=$(dialog --nocancel --inputbox "$HOSTNAME Invalid Must Be At Most 63 Characters And Only Contain A-Z and - but can not start with -" 0 0 "ArchAuto" 3>&1 1>&2 2>&3 3>&-)
done
ROOTPASS=$(dialog --nocancel --passwordbox "Enter Pasword for Root" 0 0 3>&1 1>&2 2>&3 3>&-)
USER=$(dialog --nocancel --inputbox "Enter Username" 0 0 "user" 3>&1 1>&2 2>&3 3>&-)
while ! [[ $USER =~ ^[a-z_][a-z0-9_-]{0,30}[$]?$ ]]; do
	USER=$(dialog --nocancel --inputbox "$USER Invalid Must Be At Most 32 Characters And lowercase" 0 0 $(echo "$USER" | tr '[:upper:]' '[:lower:]') 3>&1 1>&2 2>&3 3>&-)
done
USERPASS=$(dialog --nocancel --passwordbox "Enter Password for $USER" 0 0 3>&1 1>&2 2>&3 3>&-)
DESKTOP=$(dialog --nocancel --radiolist "Which Desktop Do You Want?" 0 0 0 KDE "" on Console "" off 3>&1 1>&2 2>&3 3>&-)
if [[ $DESKTOP == "KDE" ]]; then
	cat ./KDE/packages.txt >> ./Base/packages.txt
	cat ./KDE/services.txt >> ./Base/services.txt
	CONFIGS=$($(dialog --yesno "Do You Want Customized KDE Configs?" 0 0 3>&1 1>&2 2>&3 3>&-) && echo "Yes" || echo "No")
	if [[ systemd-detect-virt == "none" ]]; then
		GRAPHICS=$(dialog --nocancel --radiolist "Which Graphics Driver Do You Want" 0 0 0 AMD "" on Intel "" off NVIDIA "" off  3>&1 1>&2 2>&3 3>&-)
		if [[ $GRAPHICS == "AMD" ]]; then
			echo -e "lib32-vulkan-radeon\n" >> ./Base/packages.txt
		fi
		if [[ $GRAPHICS == "Intel" ]]; then
			echo -e "lib32-vulkan-intel\n" >> ./Base/packages.txt
			echo -e "vulkan-intel\n" >> ./Base/packages.txt
		fi
		if [[ $GRAPHICS == "NVIDIA" ]]; then
			echo -e "lib32-nvidia-utils\n" >> ./Base/packages.txt
			echo -e "lib32-systemd\n" >> ./Base/packages.txt
		fi
	else
		echo -e "lib32-vulkan-virtio\n" >> ./Base/packages.txt
		echo -e "vulkan-virtio\n" >> ./Base/packages.txt
	fi
	sed -i -z 's|#\[multilib]\n#|[multilib]\n|' /etc/pacman.conf
fi
. ./Base/base.sh
if [[ $DESKTOP == "KDE" ]]; then
	sed -i -z 's|#\[multilib]\n#|[multilib]\n|' /mnt/etc/pacman.conf
fi
if [[ $CONFIGS == "Yes" ]]; then
	. ./KDE/configure.sh
fi
ADVANCED=$(dialog --nocancel --menu "What would you like to do?" 0 0 0 "Reboot" "" "Manually Edit" "" 3>&1 1>&2 2>&3 3>&-)
if [[ $ADVANCED == "Reboot" ]]; then
	reboot
else
	clear
fi
