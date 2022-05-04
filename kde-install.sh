if [ -z ${NEWUSERNAME+x}]; then
    NEWUSERNAME="root" 
    echo "USERNAME NOT SET, DEFAULTING TO $NEWUSERNAME"
    read -p "Continue with $NEWUSERNAME?" -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
        exit
    fi
fi
pacman -S xorg kwin sddm konsole dolphin kinfocenter kate firefox kget kmail vlc kdeconnect kdiff3 krename kfind filelight htop kjots kontact korganizer plasma-systemmonitor spectacle plasma-pa plasma-disks drkonqi plasma-browser-integration plasma-desktop ssdm-kcm networkmanager-qt breeze-grub hunspell hunspell-en_us
systemctl enable sddm

cp -r ./KDE_Config_dotfiles /home/$NEWUSERNAME/
cp -r ./KDE_LOCAL_dotfiles /home/$NEWUSERNAME/