if [ -z ${USER+x}]; then
    USER=$(arch-chroot /mnt bash -c "ls -l /home/ | grep -oE '[^ ]+$'" | tail -1)
    #"'"
    #Used to fix formating on github
    echo "USERNAME NOT SET, DEFAULTING TO $USER"
    read -p "Continue with $USER? [Y/n]" -n 1 -r
    if [[ $REPLY =~ ^[Nn]$ ]]
        then
        exit
    fi
fi
cd "${0%/*}"
pacstrap /mnt xorg-server gnu-free-fonts wireplumber pipewire-jack phonon-qt5-vlc sddm konsole dolphin kwrite firefox kolourpaint kmail kcalc vlc kdeconnect kfind filelight htop kalendar plasma-systemmonitor khotkeys flameshot plasma-pa plasma-disks plasma-browser-integration plasma-desktop plasma-nm hunspell-en_us

systemctl enable sddm --root=/mnt
systemctl enable NetworkManager --root=/mnt

if [ $CONFIGS == "Yes"]; then
    cp -r KDE_Config_dotfiles /mnt/home/$USER/.config
    cp -r KDE_Local_dotfiles /mnt/home/$USER/.local
    #khotkeysrc kglobalshortcutsrc

    if [ $BOOTLOADER == "grub" ]; then
        pacstrap /mnt breeze-grub
        sed -i 's|#GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/breeze/theme.txt"|' /mnt/etc/default/grub
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    fi

    arch-chroot /mnt chown -R "$USER" /home/$USER/.config /home/$USER/.local

    cd /mnt/usr/share/applications
    rm assistant.desktop avahi-discover.desktop bssh.desktop bvnc.desktop designer.desktop linguist.desktop org.kde.kuserfeedback-console.desktop org.kde.plasma.emojier.desktop qdbusviewer.desktop qv4l2.desktop qvidcap.desktop
fi
