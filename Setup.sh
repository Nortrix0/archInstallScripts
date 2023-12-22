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
DESKTOP=$(dialog --nocancel --menu "Which Desktop Do You Want?" 0 0 0 $(find ./Desktops/* -maxdepth 0 -type d -exec basename {} \; | sed -E 's|(.+)\n?|\1 ​ |g') 3>&1 1>&2 2>&3 3>&-)
if [[ ! -f "./Desktops/$DESKTOP/no-graphics" ]] then
	sed -i -z 's|#\[multilib]\n#|[multilib]\n|' /etc/pacman.conf
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
fi
if [[ -f "./Desktops/$DESKTOP/configure.sh" ]] then
	CONFIGS=$($(dialog --yesno "Do You Want Customized $DESKTOP Configs?" 0 0 3>&1 1>&2 2>&3 3>&-) && echo "Yes" || echo "No")
fi
USEADVANCED=$(dialog --nocancel --menu "Do you want to reboot when install is done?" 0 0 0 "Yes" "" "Ask Me After Install" "" 3>&1 1>&2 2>&3 3>&-)
if [[ -f "./Desktops/$DESKTOP/pre-install.sh" ]] then
	. ./Desktops/$DESKTOP/pre-install.sh
fi
cat ./Desktops/$DESKTOP/packages.txt >> ./install_packages.txt 2>/dev/null # Cat contents of packages.txt but ignore errors if it doesn't exist
cat ./Desktops/$DESKTOP/services.txt >> ./install_services.txt 2>/dev/null # Cat contents of services.txt but ignore errors if it doesn't exist
. ./Base/base.sh
if [[ $CONFIGS == "Yes" ]] then
	cp -r "./Desktops/$DESKTOP/.config" /mnt/home/$USER/.config 2>/dev/null # Copy contents of .config but ignore errors if it doesn't exist
	cp -r "./Desktops/$DESKTOP/.local" /mnt/home/$USER/.local 2>/dev/null # Copy contents of .local but ignore errors if it doesn't exist
	arch-chroot /mnt chown -R "$USER" /home/$USER
	. ./Desktops/$DESKTOP/configure.sh
fi
if [[ -f "./Desktops/$DESKTOP/post-install.sh" ]] then
	. ./Desktops/$DESKTOP/post-install.sh
fi
if [[ $USEADVANCED == "Ask Me After Install" ]] then
	ADVANCED=$(dialog --nocancel --menu "What would you like to do?" 0 0 0 "Reboot" "" "Manually Edit" "" 3>&1 1>&2 2>&3 3>&-)
	if [[ $ADVANCED == "Reboot" ]] then
		reboot
	else
		clear
	fi
else
	reboot
fi
