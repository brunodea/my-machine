# ensure the system clock is accurate
timedatectl set-ntp true

# figure out how the disk is called (i.e., sda, sdb, sdc, ...) -- will probably be sda.
DISK=$(fdisk -l | grep /dev/sd | awk '{print $2}' | sed 's/\/dev\///' | sed 's/://')

# create partitions 
alias PARTED_CMD="parted -a optimal -s /dev/${DISK}"

PARTED_CMD mklabel gpt
PARTED_CMD mkpart ESP fat32 1MiB 513MiB 
PARTED_CMD set 1 boot on

# /
PARTED_CMD mkpart primary ext4 513MiB 65%
# /swap
PARTED_CMD mkpart primary linux-swap 65% 67%
# /home
PARTED_CMD mkpart primary ext4 67% 100%
