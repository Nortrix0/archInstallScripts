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
cp ./Base/packages.txt ./install_packages.txt
cp ./Base/services.txt ./install_services.txt
. ./Base/prompts.sh
if [[ $REBOOT == "Stop Install Now" ]] then
	exit
fi
sed -i "s|KERNEL|$kernel|" ./install_packages.txt
#Determine Microcode
sed -i "s|microcode|$([[ $(grep vendor_id /proc/cpuinfo) == *"AuthenticAMD"* ]] && echo "amd-ucode" || echo "intel-ucode")|" ./install_packages.txt
if [[ ! -n $(find . -type f -path "./\*/Desktops/$DESKTOP/no-graphics") ]] then
	sed -i -z 's|#\[multilib]\n#|[multilib]\n|' /etc/pacman.conf
	if [[ systemd-detect-virt == "none" ]] then
		GRAPHICS=$(lspci | grep -i 'VGA\|3D')
		if [[ $($GRAPHICS | wc -l) -gt 1 ]] then
			echo -e "switcheroo-control\n" >> ./install_packages.txt
		fi
		if echo $GRAPHICS | grep -qi 'AMD'; then
			echo -e "lib32-vulkan-radeon\nlib32-mesa\n" >> ./install_packages.txt
		fi
		if echo $GRAPHICS | grep -qi 'Intel'; then
			echo -e "lib32-vulkan-intel\nlib32-mesa\n" >> ./install_packages.txt
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
if [ -d "./archinstallRepo/Desktops/$DESKTOP/Configs/$CONFIGS/Flatpak" ]; then
	echo "flatpak" >> ./install_packages.txt
fi
. ./Base/base.sh
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
if [[ $CONFIGS == false ]] && [ -d "./archinstallRepo/Desktops/$DESKTOP/Configs/$CONFIGS/AUR" ]; then
	chmod 666 /mnt/etc/pacman.conf
	arch-chroot /mnt mkdir -m 777 yay
	arch-chroot /mnt su $USER -c "cd yay && git clone https://aur.archlinux.org/yay.git && makepkg -sD yay"
	arch-chroot /mnt bash -c "pacman -U --noconfirm /yay/yay/yay-1*.pkg.tar.zst"
	rm -rf /mnt/yay
	arch-chroot -u $USER /mnt yay -S --answerclean N --answerdiff N --answeredit N --answerupgrade N - < "./archinstallRepo/Desktops/$DESKTOP/Configs/$CONFIGS/AUR/packages.txt"
fi
if [ -d "./archinstallRepo/Desktops/$DESKTOP/Configs/$CONFIGS/Flatpak" ]; then
	while read f; do
		arch-chroot /mnt flatpak install -y flathub $f
	done <"./archinstallRepo/Desktops/$DESKTOP/Configs/$CONFIGS/Flatpak/packages.txt"
fi
cp -r ./*/Desktops/$DESKTOP/Configs/$CONFIGS/Copy/. /mnt/home/$USER/ 2>/dev/null # Copy contents of Copy but ignore errors if it doesn't exist
$(. ./*/Desktops/$DESKTOP/Configs/$CONFIGS/configure.sh 2>/dev/null) || echo "./*/Desktops/$DESKTOP/Configs/$CONFIGS/configure.sh NOT FOUND"
$(. ./*/Desktops/$DESKTOP/post-install.sh 2>/dev/null) || echo "./Desktops/$DESKTOP/post-install.sh NOT FOUND"
$(. ./*/Desktops/$DESKTOP/Configs/$CONFIGS/post-install.sh 2>/dev/null) || echo "./*/Desktops/$DESKTOP/Configs/$CONFIGS/post-install.sh NOT FOUND"
chown -R 1000:1000 /mnt/home/$USER
sleep 1
cp ./install.log /mnt/home/$USER/install.log 2>/dev/null # Copy contents of install.log but ignore errors if it doesn't exist
if $REBOOT == "Yes"; then
	reboot
fi
clear
