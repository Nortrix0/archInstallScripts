REPOLIST=$(find ./Repository/* -type f -exec sh -c 'echo -e $(basename "{}") $(cat "{}") on ' \;)
REPOS=$(whiptail --nocancel --checklist "Select which Repos you want to use" 0 0 5 $REPOLIST 3>&1 1>&2 2>&3 | sed 's|"||g')
for repo in $REPOS; do
	cat ./Repository/$repo | xargs -I {} git clone "{}" $repo
done
DISK=$(whiptail --nocancel --menu "Select Disk" 0 0 5 $(lsblk -rnpdo NAME,SIZE | grep -E '.*[0-9]{2,}.*G$|.*T$') 3>&1 1>&2 2>&3)
ENCRYPT=$(whiptail --yesno "Do you want to have the Drive Encrypted?" 0 0 0 3>&1 1>&2 2>&3 && echo true || echo false)
if $ENCRYPT; then
    ENCRYPTPASS=$(whiptail --nocancel --passwordbox "Enter Encryption Password" 7 0 3>&1 1>&2 2>&3)
fi
#kernel=$(whiptail --nocancel --menu "Select Kernel" 0 0 2 linux Stable linux-hardened Hardened linux-lts Longterm 3>&1 1>&2 2>&3)
kernel=linux
HOSTNAME=$(whiptail --nocancel --inputbox "Enter Hostname" 0 0 "Arch" 3>&1 1>&2 2>&3)
while ! [[ $HOSTNAME =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$ ]]; do
	HOSTNAME=$(whiptail --nocancel --inputbox "$HOSTNAME Invalid Must Be At Most 63 Characters And Only Contain A-Z and - but can not start with -" 0 0 "$HOSTNAME" 3>&1 1>&2 2>&3)
done
USER=$(whiptail --nocancel --inputbox "Enter Username" 0 0 "" 3>&1 1>&2 2>&3)
while ! [[ $USER =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]] do
	USER=$(whiptail --nocancel --inputbox "$USER Invalid Must Be At Most 32 Characters And lowercase" 0 0 $(echo "$USER" | tr '[:upper:]' '[:lower:]') 3>&1 1>&2 2>&3)
done
USERPASS=$(whiptail --nocancel --passwordbox "Enter Password for $USER" 7 0 3>&1 1>&2 2>&3)
USEROOT=$(whiptail --nocancel --noitem --menu "How do you want ROOT's password?" 0 0 0 "Same As User" "" "New Password" "" "Disabled" "" 3>&1 1>&2 2>&3)
if [[ $USEROOT == "Same As User" ]] then
	ROOTPASS=$USERPASS
elif [[ $USEROOT == "New Password" ]] then
	ROOTPASS=$(whiptail --nocancel --passwordbox "Enter Password for Root" 7 0 3>&1 1>&2 2>&3)
fi
DESKTOP=$(whiptail --nocancel --noitem --menu "Which Desktop Do You Want?" 0 0 0 $(find ./*/Desktops/* -maxdepth 0 -type d  -printf '%f ​ ') 3>&1 1>&2 2>&3)
CONFIGS=$( [[ ! $( find ./*/Desktops/$DESKTOP/Configs) ]] && echo "None" || echo $(whiptail --nocancel --noitem --menu "Do You Want Customized $DESKTOP Configs?" 0 0 0 None ​ $(find ./*/Desktops/$DESKTOP/Configs/* -maxdepth 0 -type d -printf '%f ​ ') 3>&1 1>&2 2>&3))
if [[ $CONFIGS != "None" ]] then
	CHAOTIC=$(whiptail --yesno "Do you want to use Chaotic AUR?" 0 0 0 3>&1 1>&2 2>&3 && echo true || echo false)
fi
$(. ./*/Desktops/$DESKTOP/prompts.sh || true) || echo "./*/Desktops/$DESKTOP/prompts.sh NOT FOUND"
$(. ./*/Desktops/$DESKTOP/Configs/$CONFIGS/prompts.sh || true) || echo "./*/Desktops/$DESKTOP/Configs/$CONFIGS/prompts.sh NOT FOUND"
BACKUP=$(whiptail --nocancel --noitem --menu "Which Backup Option do you prefer?" 0 0 0 Snapper ​ Timeshift ​ 3>&1 1>&2 2>&3)
REBOOT=$(whiptail --nocancel --noitem --menu "Do you want to reboot when install is done?" 0 0 0 Yes ​ No ​ "Stop Install Now" ​ 3>&1 1>&2 2>&3)
#REBOOT=$(whiptail --yesno "Do you want to reboot when install is done?" 0 0 0 3>&1 1>&2 2>&3 && echo true || echo false)
# $(whiptail --nocancel [inputbox passwordbox menu yesno] [menu/noitem] TITLE [passwordbox/7 else/0] 0 [menu/0 yesno/0] TEXT 3>&1 1>&2 2>&3)
