cp -r ./KDE/KDE_Config_dotfiles /mnt/home/$USER/.config
cp -r ./KDE/KDE_Local_dotfiles /mnt/home/$USER/.local
#khotkeysrc kglobalshortcutsrc

arch-chroot /mnt chown -R "$USER" /home/$USER/.config /home/$USER/.local

sed -i 's/Numlock=.*/Numlock=on/' /mnt/usr/lib/sddm/sddm.conf.d/default.conf
rm /mnt/usr/share/applications/{assistant.desktop,avahi-discover.desktop,bssh.desktop,bvnc.desktop,designer.desktop,linguist.desktop,org.kde.kuserfeedback-console.desktop,org.kde.plasma.emojier.desktop,qdbusviewer.desktop,qv4l2.desktop,qvidcap.desktop}
