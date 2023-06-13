cp -r ./KDE/KDE_Config_dotfiles /mnt/home/$USER/.config
cp -r ./KDE/KDE_Local_dotfiles /mnt/home/$USER/.local
#khotkeysrc kglobalshortcutsrc

if [ $BOOTLOADER == "grub" ]; then
    sed -i 's|#GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/breeze/theme.txt"|' /mnt/etc/default/grub
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
fi

arch-chroot /mnt ln -rsf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
arch-chroot /mnt chown -R "$USER" /home/$USER/.config /home/$USER/.local

sed -i 's/Numlock=.*/Numlock=on/' /usr/lib/sddm/sddm.conf.d/default.conf
rm /mnt/usr/share/applications/{assistant.desktop,avahi-discover.desktop,bssh.desktop,bvnc.desktop,designer.desktop,linguist.desktop,org.kde.kuserfeedback-console.desktop,org.kde.plasma.emojier.desktop,qdbusviewer.desktop,qv4l2.desktop,qvidcap.desktop}
