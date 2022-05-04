pacman -S xorg kwin sddm konsole dolphin kinfocenter kate firefox kget kmail vlc kdeconnect kdiff3 krename kfind filelight htop kjots kontact korganizer plasma-systemmonitor spectacle plasma-pa plasma-disks drkonqi plasma-browser-integration plasma-desktop ssdm-kcm networkmanager-qt breeze-grub hunspell hunspell-en_us
systemctl enable sddm
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 5 --group Configuration --group General --key launchers preferred://browser,preferred://filemanager,applications:org.kde.konsole.desktop
kwriteconfig5 --file ../.local/share/dolphin/view_properties/global/.direcotry --group Settings --key HiddenFilesShown --type bool false
kwriteconfig5 --file dolphinrc --group General --key BrowseThoughArchives --type bool true
kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage org.kde.breezedark.desktop
kwriteconfig5 --file kdeglobals --group KSplash --key Theme None
kwriteconfig5 --file ksmserverrc --group General --key confirmLogout --type bool false
#kwriteconfig5 --file dolphinrc --group PreviewSettings --key Plugins+=textthumbnail
kwriteconfig5 --file dolphinrc --group General --key ShowToolTips --type bool true
kwriteconfig5 --file dolphinrc --group General --key ShowFullPath --type bool true
kwriteconfig5 --file dolphinrc --group ContextMenu --key ShowCopyMove --type bool true
#Kate
kwriteconfig5 --file katerc --group KTextEditor Renderer --key Show Whole Bracket Expression --type bool true
kwriteconfig5 --file katerc --group KTextEditor Renderer --key Animate Bracket Matching --type bool true
kwriteconfig5 --file katerc --group KTextEditor View --key Show Line Count --type bool true
kwriteconfig5 --file katerc --group KTextEditor View --key Show Word Count --type bool true
kwriteconfig5 --file katerc --group KTextEditor View --key Auto Brackets --type bool true
kwriteconfig5 --file katerc --group KTextEditor Document --key On-The-Fly Spellcheck --type bool true