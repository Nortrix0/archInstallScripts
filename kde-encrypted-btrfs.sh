clear
cd "${0%/*}"
. ./base-encrypted-btrfs.sh |& tee kde-encrypted-btrfs.log
. ./kde-install.sh |& tee -a kde-encrypted-btrfs.log