cd "${0%/*}"
clear
#Set to use US Mirrors with HTTPS
#curl 'https://archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4' -o /etc/pacman.d/mirrorlist
#sed -i 's/#Server/Server/' /etc/pacman.d/mirrorlist
#Set ParallelDownloads on ArchIso to help speed up install
sed -i 's|^#ParallelDownloads.*$|ParallelDownloads = 10|' /etc/pacman.conf
pacman -Sy dialog --noconfirm
#mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
#reflector --latest 20 --protocol https --sort rate --country 'United States' --save /etc/pacman.d/mirrorlist
DISK=$(dialog --nocancel --menu "Select Disk" 0 0 5 $(lsblk -rnpSo NAME,SIZE) 3>&1 1>&2 2>&3 3>&-)
#kernel=$(dialog --nocancel --menu "Select Kernel" 0 0 2 linux Stable linux-hardened Hardened linux-lts Longterm 3>&1 1>&2 2>&3 3>&-)
kernel=linux
cp ./Base/packages.txt ./install_packages.txt
cp ./Base/services.txt ./install_services.txt
sed -i "s|KERNEL|$kernel|" ./install_packages.txt
#Determine Microcode
microcode=$([[ $(grep vendor_id /proc/cpuinfo) == *"AuthenticAMD"* ]] && echo "amd-ucode" || echo "intel-ucode")
sed -i "s|microcode|$microcode|" ./install_packages.txt
HOSTNAME=$(dialog --nocancel --inputbox "Enter Hostname" 0 0 "ArchAuto" 3>&1 1>&2 2>&3 3>&-)
while ! [[ $USER =~ ^[a-z_][a-z0-9_-]{0,30}[$]?$ ]]; do
	HOSTNAME=$(dialog --nocancel --inputbox "$HOSTNAME Invalid Must Be At Most 63 Characters And Only Contain A-Z and - but can not start with -" 0 0 "ArchAuto" 3>&1 1>&2 2>&3 3>&-)
done
USER=$(dialog --nocancel --inputbox "Enter Username" 0 0 "user" 3>&1 1>&2 2>&3 3>&-)
while ! [[ $USER =~ ^[a-z_][a-z0-9_-]{0,30}[$]?$ ]] do
	USER=$(dialog --nocancel --inputbox "$USER Invalid Must Be At Most 32 Characters And lowercase" 0 0 $(echo "$USER" | tr '[:upper:]' '[:lower:]') 3>&1 1>&2 2>&3 3>&-)
done
USERPASS=$(dialog --nocancel --passwordbox "Enter Password for $USER" 0 0 3>&1 1>&2 2>&3 3>&-)
USEROOT=$(dialog --nocancel --menu "How do you want ROOT's password?" 0 0 0 "Same As User" "" "New Password" "" "Disabled" "" 3>&1 1>&2 2>&3 3>&-)
if [[ $USEROOT == "Same As User" ]] then
	ROOTPASS=$USERPASS
elif [[ $USEROOT == "New Password" ]] then
	ROOTPASS=$(dialog --nocancel --passwordbox "Enter Pasword for Root" 0 0 3>&1 1>&2 2>&3 3>&-)
fi
DESKTOP=$(dialog --nocancel --menu "Which Desktop Do You Want?" 0 0 0 KDE "" KDE6 "" Console "" 3>&1 1>&2 2>&3 3>&-)
if [[ $DESKTOP == "KDE" ]] then
	cat ./KDE/packages.txt >> ./install_packages.txt
	cat ./KDE/services.txt >> ./install_services.txt
	CONFIGS=$($(dialog --yesno "Do You Want Customized KDE Configs?" 0 0 3>&1 1>&2 2>&3 3>&-) && echo "Yes" || echo "No")
	if [[ systemd-detect-virt == "none" ]] then
		GRAPHICS=$(dialog --nocancel --menu "Which Graphics Driver Do You Want" 0 0 0 AMD "" Intel "" NVIDIA "" 3>&1 1>&2 2>&3 3>&-)
		if [[ $GRAPHICS == "AMD" ]] then
			echo -e "lib32-vulkan-radeon\n" >> ./install_packages.txt
		elif [[ $GRAPHICS == "Intel" ]] then
			echo -e "lib32-vulkan-intel\nvulkan-intel\n" >> ./install_packages.txt
		elif [[ $GRAPHICS == "NVIDIA" ]] then
			echo -e "lib32-nvidia-utils\nlib32-systemd\n" >> ./install_packages.txt
		fi
	else
		echo -e "lib32-vulkan-virtio\nvulkan-virtio\n" >> ./install_packages.txt
	fi
	sed -i -z 's|#\[multilib]\n#|[multilib]\n|' /etc/pacman.conf
elif [[ $DESKTOP == "KDE6" ]] then
 		echo -e "[kde-unstable]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
		echo -e "plasma-meta" >> ./install_packages.txt
fi
USEADVANCED=$(dialog --nocancel --menu "Do you want to reboot when install is done?" 0 0 0 "Yes" "" "Ask Me After Install" "" 3>&1 1>&2 2>&3 3>&-)
. ./Base/base.sh
if [[ $CONFIGS == "Yes" ]] then
	. ./KDE/configure.sh
fi
if [[ $DESKTOP == "KDE6" ]] then
	echo -e "[kde-unstable]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /mnt/etc/pacman.conf
fi
if [[ $USERADVANCED == "Ask Me After Install" ]] then
	ADVANCED=$(dialog --nocancel --menu "What would you like to do?" 0 0 0 "Reboot" "" "Manually Edit" "" 3>&1 1>&2 2>&3 3>&-)
	if [[ $ADVANCED == "Reboot" ]] then
		reboot
	else
		clear
	fi
fi
