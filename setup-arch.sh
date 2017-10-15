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

# The disk names are determined by the order they were created above.
BOOT_DISK="${DISK}"1
ROOT_DISK="${DISK}"2
SWAP_DISK="${DISK}"3
HOME_DISK="${DISK}"4

# parted already formats them.
#mkfs.fat -F32 /dev/$BOOT_DISK
#mkfs.ext4 /dev/$ROOT_DISK
#mkfs.ext4 /dev/$HOME_DISK

###################################
# mount the filesystem structure. #
###################################
mount /dev/$ROOT_DISK /mnt
mkdir /mnt/boot
mount /dev/$BOOT_DISK /mnt/boot
mkdir /mnt/home
mount /dev/$HOME_DISK /mnt/home
###################################

##################################################################
# make the Brazilian server the first of the list in mirrorlist. #
##################################################################
grep 'archlinux-br\.mirror' -B 1 /etc/pacman.d/mirrorlist > tmp1
grep -v 'archlinux-br\.mirror' /etc/pacman.d/mirrorlist > tmp2
cat tmp2 >> tmp1
mv tmp1 /etc/pacman.d/mirrorlist
rm tmp2
################################################################

pacstrap /mnt base
genfstab -L /mnt >> /mnt/etc/fstab

arch-chroot /mnt
