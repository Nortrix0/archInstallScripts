cd "${0%/*}"
while getopts "d" option; do
  case $option in
    d)
      script -qc "DEBUG=true ./Setup.sh" ./install.log
	  exit
      ;;
    *)
      echo "Usage: $0 [-d]"
      ;;
  esac
done
if [[ $DEBUG ]] then
	set -x
fi
. ./Base/prompts.sh
cp ./Base/packages.txt ./install_packages.txt
cp ./Base/services.txt ./install_services.txt
sed -i "s|KERNEL|$kernel|" ./install_packages.txt
#Determine Microcode
sed -i "s|microcode|$([[ $(grep vendor_id /proc/cpuinfo) == *"AuthenticAMD"* ]] && echo "amd-ucode" || echo "intel-ucode")|" ./install_packages.txt
if [[ ! -f "./*/Desktops/$DESKTOP/no-graphics" ]] then
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
$(. ./*/Desktops/$DESKTOP/pre-install.sh 2>/dev/null) || echo "./*/Desktops/$DESKTOP/pre-install.sh NOT FOUND"
$(. ./*/Desktops/$DESKTOP/Configs/$CONFIGS/pre-install.sh 2>/dev/null) || echo "./*/Desktops/$DESKTOP/Configs/$CONFIGS/pre-install.sh NOT FOUND"
cat ./*/Desktops/$DESKTOP/packages.txt ./*/Programs/Backup/$BACKUP/packages.txt ./*/Desktops/$DESKTOP/Configs/$CONFIGS/packages.txt >> ./install_packages.txt 2>/dev/null # Cat contents of packages.txt but ignore errors if it doesn't exist
cat ./*/Desktops/$DESKTOP/services.txt ./*/Programs/Backup/$BACKUP/services.txt ./*/Desktops/$DESKTOP/Configs/$CONFIGS/services.txt >> ./install_services.txt 2>/dev/null # Cat contents of services.txt but ignore errors if it doesn't exist
#Set ParallelDownloads on ArchIso to help speed up install
sed -i 's|#Color|Color|;s|^#ParallelDownloads.*$|ParallelDownloads = 10|' /etc/pacman.conf
echo "Finding best servers, this may take a minute!"
reflector --latest 20 --protocol https --sort rate --country 'United States' --save /etc/pacman.d/mirrorlist # Regenerate mirrorlist to use US based ones
pacman -Sy archlinux-keyring --noconfirm
if [[ -d "./*/Desktops/$DESKTOP/Configs/$CONFIG/Flatpak"]]
	echo "flatpak" >> ./install_packages.txt
fi
. ./Base/base.sh
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
if [[ -d "./*/Desktops/$DESKTOP/Configs/$CONFIG/AUR"]]
	arch-chroot /mnt git clone https://aur.archlinux.org/yay.git
	chmod 666 /mnt/etc/pacman.conf
	chmod 666 /mnt/yay
	arch-chroot /mnt echo $USERPASS | su - $USER -c "cd /yay/ && makepkg"
	arch-chroot /mnt yay -S --answerclean A --answerdiff N --answeredit N --answerupgrade A - < "./*/Desktops/$DESKTOP/Configs/$CONFIG/AUR/packages.txt"
fi
if [[ -d "./*/Desktops/$DESKTOP/Configs/$CONFIG/Flatpak"]]
	while read f; do
		arch-chroot /mnt flatpak install flathub $f
	done <"./*/Desktops/$DESKTOP/Configs/$CONFIG/Flatpak/packages.txt"
fi
cp -r ./*/Desktops/$DESKTOP/Configs/$CONFIGS/Copy/. /mnt/home/$USER/ 2>/dev/null # Copy contents of Copy but ignore errors if it doesn't exist
$(. ./*/Desktops/$DESKTOP/Configs/$CONFIGS/configure.sh 2>/dev/null) || echo "./*/Desktops/$DESKTOP/Configs/$CONFIGS/configure.sh NOT FOUND"
$(. ./*/Desktops/$DESKTOP/post-install.sh 2>/dev/null) || echo "./Desktops/$DESKTOP/post-install.sh NOT FOUND"
$(. ./*/Desktops/$DESKTOP/Configs/$CONFIGS/post-install.sh 2>/dev/null) || echo "./*/Desktops/$DESKTOP/Configs/$CONFIGS/post-install.sh NOT FOUND"
chown -R 1000:1000 /mnt/home/$USER
sleep 1
cp ./install.log /mnt/home/$USER/install.log 2>/dev/null # Copy contents of install.log but ignore errors if it doesn't exist
if $REBOOT; then
	reboot
fi
clear
