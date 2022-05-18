clear
set -xv
cd "${0%/*}"
. ./base-btrfs.sh |& tee kde-btrfs.log
. ./kde-install.sh |& tee -a kde-btrfs.log