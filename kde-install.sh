#xorg
#kwin
#sddm
#konsole
#dolphin
#kinfocenter
#kate
#firefox
#kget
#kmail
#vlc
#kdeconnect
#kdiff3
#krename
#kfind
#filelight
#htop
#kjots
#kontact
#korganizer
#plasma-systemmonitor
#spectacle
#plasma-pa
#plasma-disks
#drkonqi
#plasma-browser-integration
#plasma-desktop
#ssdm-kcm
#networkmanager-qt
#breeze-grub

kwriteconfig5 --file /home/$NEWUSERNAME/.local/share/dolphin/view_properties/global/.direcotry --group Settings --key HiddenFilesShown --type bool false
kwriteconfig5 --file /home/$NEWUSERNAME/.config/dolphinrc --group General --key BrowseThoughArchives --type bool true
kwriteconfig5 --file /home/$NEWUSERNAME/.config/kdeglobals --group KDE --key LookAndFeelPackage org.kde.breezedark.desktop
kwriteconfig5 --file /home/$NEWUSERNAME/.config/kdeglobals --group KSplash --key Theme None
kwriteconfig5 --file /home/$NEWUSERNAME/.config/ksmserverrc --group General --key confirmLogout --type bool false

