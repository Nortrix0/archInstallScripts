#khotkeysrc kglobalshortcutsrc

sed -i 's|Numlock=.*|Numlock=on|' /mnt/usr/lib/sddm/sddm.conf.d/default.conf
echo "NoDisplay=true" | tee -a /mnt/usr/share/applications/{assistant.desktop,avahi-discover.desktop,bssh.desktop,bvnc.desktop,designer.desktop,linguist.desktop,org.kde.kuserfeedback-console.desktop,org.kde.plasma.emojier.desktop,qdbusviewer.desktop,qv4l2.desktop,qvidcap.desktop}
