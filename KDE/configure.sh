cp -r ./KDE/.config /mnt/home/$USER/.config
cp -r ./KDE/.local /mnt/home/$USER/.local
#khotkeysrc kglobalshortcutsrc

arch-chroot /mnt chown -R "$USER" /home/$USER/.config /home/$USER/.local
sed -i -z 's|#\[multilib]\n#|[multilib]\n|' /mnt/etc/pacman.conf
sed -i 's/Numlock=.*/Numlock=on/' /mnt/usr/lib/sddm/sddm.conf.d/default.conf
rm /mnt/usr/share/applications/{assistant.desktop,avahi-discover.desktop,bssh.desktop,bvnc.desktop,designer.desktop,linguist.desktop,org.kde.kuserfeedback-console.desktop,org.kde.plasma.emojier.desktop,qdbusviewer.desktop,qv4l2.desktop,qvidcap.desktop}
