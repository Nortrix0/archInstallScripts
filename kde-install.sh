if [ -z ${NEWUSERNAME+x}]; then
    NEWUSERNAME="root" 
    echo "USERNAME NOT SET, DEFAULTING TO $NEWUSERNAME"
    read -p "Continue with $NEWUSERNAME? [Y/n]" -n 1 -r
    if [[ $REPLY =~ ^[Nn]$ ]]
        then
        exit
    fi
fi
pacstrap /mnt xorg kwin sddm konsole dolphin kinfocenter kate firefox kmail kcalc vlc kdeconnect kfind filelight htop korganizer plasma-systemmonitor flameshot plasma-pa plasma-disks plasma-browser-integration plasma-desktop plasma-nm breeze-grub hunspell hunspell-en_us

pacstrap /mnt xorg-server gnu-free-fonts pipewire-media-session jack2 phonon-qt5-vlc

check kinfocenter plasma-nm

systemctl enable sddm --root=/mnt

mkdir /mnt/home/$NEWUSERNAME/.config
cp -r ./KDE_Config_dotfiles/* "/mnt/home/$NEWUSERNAME/.config"
mkdir /mnt/home/$NEWUSERNAME/.local
cp -r ./KDE_Local_dotfiles/* "/mnt/home/$NEWUSERNAME/.local"

arch-chroot /mnt chown -R "$NEWUSERNAME" /home/$NEWUSERNAME/.config /home/$NEWUSERNAME/.local

cd /mnt/usr/share/applications
rm assistant.desktop avahi-discover.desktop bssh.desktop bvnc.desktop designer.desktop linguist.desktop org.kde.kuserfeedback-console.desktop qdbusviewer.desktop qv4l2.desktop qvidcap.desktop