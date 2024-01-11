cd "${0%/*}"
while getopts "d" option; do
  case $option in
    d)
      script -qc "bash -x -c 'DEBUG=true ./Setup.sh'" ./install.log
	  exit
      ;;
    *)
      echo "Usage: $0 [-d]"
      ;;
  esac
done
if $DEBUG; then
	set -x
fi
#Set ParallelDownloads on ArchIso to help speed up install
sed -i 's|#Color|Color|;s|^#ParallelDownloads.*$|ParallelDownloads = 10|' /etc/pacman.conf
DISK=$(whiptail --output-fd 3 --nocancel --menu "Select Disk" 0 0 5 $(lsblk -rnpSo NAME,SIZE) 3>&1 1>&2 2>&3)
#kernel=$(whiptail --output-fd 3 --nocancel --menu "Select Kernel" 0 0 2 linux Stable linux-hardened Hardened linux-lts Longterm 3>&1 1>&2 2>&3)
kernel=linux
cp ./Base/packages.txt ./install_packages.txt
cp ./Base/services.txt ./install_services.txt
sed -i "s|KERNEL|$kernel|" ./install_packages.txt
#Determine Microcode
sed -i "s|microcode|$([[ $(grep vendor_id /proc/cpuinfo) == *"AuthenticAMD"* ]] && echo "amd-ucode" || echo "intel-ucode")|" ./install_packages.txt
HOSTNAME=$(whiptail --output-fd 3 --nocancel --inputbox "Enter Hostname" 0 0 "ArchAuto" 3>&1 1>&2 2>&3)
while ! [[ $USER =~ ^[a-z_][a-z0-9_-]{0,30}[$]?$ ]]; do
	HOSTNAME=$(whiptail --output-fd 3 --nocancel --inputbox "$HOSTNAME Invalid Must Be At Most 63 Characters And Only Contain A-Z and - but can not start with -" 0 0 "ArchAuto" 3>&1 1>&2 2>&3)
done
USER=$(whiptail --output-fd 3 --nocancel --inputbox "Enter Username" 0 0 "user" 3>&1 1>&2 2>&3)
while ! [[ $USER =~ ^[a-z_][a-z0-9_-]{0,30}[$]?$ ]] do
	USER=$(whiptail --output-fd 3 --nocancel --inputbox "$USER Invalid Must Be At Most 32 Characters And lowercase" 0 0 $(echo "$USER" | tr '[:upper:]' '[:lower:]') 3>&1 1>&2 2>&3)
done
USERPASS=$(whiptail --output-fd 3 --nocancel --passwordbox "Enter Password for $USER" 0 0 3>&1 1>&2 2>&3)
USEROOT=$(whiptail --output-fd 3 --nocancel --menu "How do you want ROOT's password?" 0 0 0 "Same As User" "" "New Password" "" "Disabled" "" 3>&1 1>&2 2>&3)
if [[ $USEROOT == "Same As User" ]] then
	ROOTPASS=$USERPASS
elif [[ $USEROOT == "New Password" ]] then
	ROOTPASS=$(whiptail --output-fd 3 --nocancel --passwordbox "Enter Password for Root" 0 0 3>&1 1>&2 2>&3)
fi
DESKTOP=$(whiptail --output-fd 3 --nocancel --menu "Which Desktop Do You Want?" 0 0 0 $(find ./Desktops/* -maxdepth 0 -type d  -printf '%f ​ ') 3>&1 1>&2 2>&3)
if [[ ! -f "./Desktops/$DESKTOP/no-graphics" ]] then
	sed -i -z 's|#\[multilib]\n#|[multilib]\n|' /etc/pacman.conf
	if [[ systemd-detect-virt == "none" ]] then
		GRAPHICS=$(lspci | grep -i 'VGA\|3D')
		if [[ $($GRAPHICS | wc -l) -gt 1 ]] then
			echo -e "switcheroo-control\n" >> ./install_packages.txt
		fi
		if echo $GRAPHICS | grep -qi 'AMD'; then
			echo -e "lib32-vulkan-radeon\n" >> ./install_packages.txt
		fi
		if echo $GRAPHICS | grep -qi 'Intel'; then
			echo -e "lib32-vulkan-intel\nvulkan-intel\n" >> ./install_packages.txt
		fi
		if echo $GRAPHICS | grep -qi 'NVIDIA'; then
			echo -e "lib32-nvidia-utils\nlib32-systemd\n" >> ./install_packages.txt
		fi
	else
		echo -e "lib32-vulkan-virtio\nvulkan-virtio\n" >> ./install_packages.txt
	fi
fi
CONFIGS=$( [[ ! -d "./Desktops/$DESKTOP/Configs" ]] && echo "None" || echo $(whiptail --output-fd 3 --nocancel --menu "Do You Want Customized $DESKTOP Configs?" 0 0 0 None ​ $(find ./Desktops/$DESKTOP/Configs/* -maxdepth 0 -type d -printf '%f ​ ') 3>&1 1>&2 2>&3))
BACKUP=$(whiptail --output-fd 3 --nocancel --menu "Which Backup Option do you prefer?" 0 0 0 Snapper ​ Timeshift ​ 3>&1 1>&2 2>&3)
USEADVANCED=$(whiptail --output-fd 3 --nocancel --menu "Do you want to reboot when install is done?" 0 0 0 "Yes" "" "Ask Me After Install" "" 3>&1 1>&2 2>&3)
. ./Desktops/$DESKTOP/pre-install.sh 2>/dev/null || echo "./Desktops/$DESKTOP/pre-install.sh NOT FOUND"
. ./Desktops/$DESKTOP/Configs/$CONFIGS/pre-install.sh 2>/dev/null || echo "./Desktops/$DESKTOP/Configs/$CONFIGS/pre-install.sh NOT FOUND"
cat ./Desktops/$DESKTOP/packages.txt ./Programs/Backup/$BACKUP/packages.txt ./Desktops/$DESKTOP/Configs/$CONFIGS/packages.txt >> ./install_packages.txt 2>/dev/null # Cat contents of packages.txt but ignore errors if it doesn't exist
cat ./Desktops/$DESKTOP/services.txt ./Desktops/$DESKTOP/Configs/$CONFIGS/services.txt >> ./install_services.txt 2>/dev/null # Cat contents of services.txt but ignore errors if it doesn't exist
echo "Finding best servers, this may take a minute!"
reflector --latest 20 --protocol https --sort rate --country 'United States' --save /etc/pacman.d/mirrorlist # Regenerate mirrorlist to use US based ones
pacman -Sy archlinux-keyring --noconfirm
. ./Base/base.sh
cp -r "./Desktops/$DESKTOP/Configs/$CONFIGS/Copy/." /mnt/home/$USER/ 2>/dev/null # Copy contents of Copy but ignore errors if it doesn't exist
. ./Desktops/$DESKTOP/Configs/$CONFIGS/configure.sh 2>/dev/null || echo "./Desktops/$DESKTOP/Configs/$CONFIGS/configure.sh NOT FOUND"
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
. ./Desktops/$DESKTOP/post-install.sh 2>/dev/null || echo "./Desktops/$DESKTOP/post-install.sh NOT FOUND"
. ./Desktops/$DESKTOP/Configs/$CONFIGS/post-install.sh 2>/dev/null || echo "./Desktops/$DESKTOP/Configs/$CONFIGS/post-install.sh NOT FOUND"
chown -R 1000:1000 /mnt/home/$USER
if [[ $USEADVANCED == "Ask Me After Install" ]] then
	ADVANCED=$(whiptail --output-fd 3 --nocancel --menu "What would you like to do?" 0 0 0 "Reboot" "" "Manually Edit" "" 3>&1 1>&2 2>&3)
	if [[ $ADVANCED == "Manually Edit" ]] then
		sleep 1
		cp ./install.log /mnt/home/$USER/install.log 2>/dev/null # Copy contents of install.log but ignore errors if it doesn't exist
		clear
		exit
	fi
fi
sleep 1
cp ./install.log /mnt/home/$USER/install.log 2>/dev/null # Copy contents of install.log but ignore errors if it doesn't exist
reboot
