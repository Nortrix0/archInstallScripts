DISK=$(whiptail --output-fd 3 --nocancel --menu "Select Disk" 0 0 5 $(lsblk -rnpSo NAME,SIZE) 3>&1 1>&2 2>&3)
#kernel=$(whiptail --output-fd 3 --nocancel --menu "Select Kernel" 0 0 2 linux Stable linux-hardened Hardened linux-lts Longterm 3>&1 1>&2 2>&3)
kernel=linux
HOSTNAME=$(whiptail --output-fd 3 --nocancel --inputbox "Enter Hostname" 0 0 "ArchAuto" 3>&1 1>&2 2>&3)
while ! [[ $USER =~ ^[a-z_][a-z0-9_-]{0,30}[$]?$ ]]; do
	HOSTNAME=$(whiptail --output-fd 3 --nocancel --inputbox "$HOSTNAME Invalid Must Be At Most 63 Characters And Only Contain A-Z and - but can not start with -" 0 0 "ArchAuto" 3>&1 1>&2 2>&3)
done
USER=$(whiptail --output-fd 3 --nocancel --inputbox "Enter Username" 0 0 "user" 3>&1 1>&2 2>&3)
while ! [[ $USER =~ ^[a-z_][a-z0-9_-]{0,30}[$]?$ ]] do
	USER=$(whiptail --output-fd 3 --nocancel --inputbox "$USER Invalid Must Be At Most 32 Characters And lowercase" 0 0 $(echo "$USER" | tr '[:upper:]' '[:lower:]') 3>&1 1>&2 2>&3)
done
USERPASS=$(whiptail --output-fd 3 --nocancel --passwordbox "Enter Password for $USER" 0 0 3>&1 1>&2 2>&3)
USEROOT=$(whiptail --output-fd 3 --nocancel --menu "How do you want ROOT's password?" 0 0 0 "Same As User" "" "New Password" "" "Disabled" "" 3>&1 1>&2 2>&3)
if [[ $USEROOT == "Same As User" ]] then
	ROOTPASS=$USERPASS
elif [[ $USEROOT == "New Password" ]] then
	ROOTPASS=$(whiptail --output-fd 3 --nocancel --passwordbox "Enter Password for Root" 0 0 3>&1 1>&2 2>&3)
fi
DESKTOP=$(whiptail --output-fd 3 --nocancel --menu "Which Desktop Do You Want?" 0 0 0 $(find ./Desktops/* -maxdepth 0 -type d  -printf '%f ​ ') 3>&1 1>&2 2>&3)
CONFIGS=$( [[ ! -d "./Desktops/$DESKTOP/Configs" ]] && echo "None" || echo $(whiptail --output-fd 3 --nocancel --menu "Do You Want Customized $DESKTOP Configs?" 0 0 0 None ​ $(find ./Desktops/$DESKTOP/Configs/* -maxdepth 0 -type d -printf '%f ​ ') 3>&1 1>&2 2>&3))
BACKUP=$(whiptail --output-fd 3 --nocancel --menu "Which Backup Option do you prefer?" 0 0 0 Snapper ​ Timeshift ​ 3>&1 1>&2 2>&3)
USEADVANCED=$(whiptail --output-fd 3 --nocancel --menu "Do you want to reboot when install is done?" 0 0 0 "Yes" "" "Ask Me After Install" "" 3>&1 1>&2 2>&3)