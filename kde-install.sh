if [ -z ${NEWUSERNAME+x}]; then
    #NEWUSERNAME="root" 
    NEWUSERNAME=$(arch-chroot /mnt bash -c "ls -l /home/ | grep -oE '[^ ]+$'" | tail -1) 
    echo "USERNAME NOT SET, DEFAULTING TO $NEWUSERNAME"
    read -p "Continue with $NEWUSERNAME? [Y/n]" -n 1 -r
    if [[ $REPLY =~ ^[Nn]$ ]]
        then
        exit
    fi
fi
pacstrap /mnt xorg-server gnu-free-fonts wireplumber pipewire-jack phonon-qt5-vlc sddm konsole dolphin kwrite firefox kmail kcalc vlc kdeconnect kfind filelight htop korganizer plasma-systemmonitor flameshot plasma-pa plasma-disks plasma-browser-integration plasma-desktop plasma-nm breeze-grub hunspell hunspell-en_us

systemctl enable sddm --root=/mnt

cd /mnt/home/*/
mkdir .config
mkdir .local
cd "${0%/*}"
cp -r KDE_Config_dotfiles/* /mnt/home/*/.config
cp -r KDE_Local_dotfiles/* /mnt/home/*/.local

arch-chroot /mnt chown -R "$NEWUSERNAME" /home/$NEWUSERNAME/.config /home/$NEWUSERNAME/.local

cd /mnt/usr/share/applications
rm assistant.desktop avahi-discover.desktop bssh.desktop bvnc.desktop designer.desktop linguist.desktop org.kde.kuserfeedback-console.desktop org.kde.plasma.emojier.desktop qdbusviewer.desktop qv4l2.desktop qvidcap.desktop