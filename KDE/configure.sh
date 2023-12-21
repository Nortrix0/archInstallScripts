#cp -r ./KDE/KDE_Config_dotfiles /mnt/home/$USER/.config
cp -r ./KDE/KDE_Local_dotfiles /mnt/home/$USER/.local
#khotkeysrc kglobalshortcutsrc

arch-chroot /mnt chown -R "$USER" /home/$USER/.config /home/$USER/.local
arch-chroot /mnt lookandfeeltool -a org.kde.breezedark.desktop
arch-chroot /mnt kwriteconfig5 --file ksplashrc --group KSplash --key Engine none
arch-chroot /mnt kwriteconfig5 --file ksmserverrc --group General --key confirmLogout false
arch-chroot /mnt kwriteconfig5 --file kscreenlockerrc --group Daemon --key Timeout 15
arch-chroot /mnt kwriteconfig5 --file dolphinrc --group General --key ShowFullPath true
arch-chroot /mnt kwriteconfig5 --file katerc --group KTextEditor Document --key On-The-Fly Spellcheck true
arch-chroot /mnt kwriteconfig5 --file katerc --group KTextEditor View --key Show Line Count true
arch-chroot /mnt kwriteconfig5 --file katerc --group KTextEditor View --key Show Word Count true
sed -i -z 's|#\[multilib]\n#|[multilib]\n|' /mnt/etc/pacman.conf
sed -i 's/Numlock=.*/Numlock=on/' /mnt/usr/lib/sddm/sddm.conf.d/default.conf
rm /mnt/usr/share/applications/{assistant.desktop,avahi-discover.desktop,bssh.desktop,bvnc.desktop,designer.desktop,linguist.desktop,org.kde.kuserfeedback-console.desktop,org.kde.plasma.emojier.desktop,qdbusviewer.desktop,qv4l2.desktop,qvidcap.desktop}
