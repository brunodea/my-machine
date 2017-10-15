#!/bin/bash

$ROOT_PWD=$1
if [ -z $ROOT_PWD ]; then
	echo "Aborting. Missing root password."
	exit 1
fi

echo "Setting system clock..."
# ensure the system clock is accurate
timedatectl set-ntp true

echo "Figuring out disk name..."
# figure out how the disk is called (i.e., sda, sdb, sdc, ...) -- will probably be sda.
DISK=$(fdisk -l | grep /dev/sd | awk '{print $2}' | sed 's/\/dev\///' | sed 's/://')

# create partitions 
alias PARTED_CMD="parted -a optimal -s /dev/${DISK}"

echo "Making partion label MBR..."
PARTED_CMD mklabel msdos
echo "Making partition for Boot..."
PARTED_CMD mkpart primary ext4 1MiB 100MiB
PARTED_CMD set 1 boot on
# /
echo "Making partition for Root..."
PARTED_CMD mkpart primary ext4 100MiB 65%
# /swap
echo "Making partigion for Swap..."
PARTED_CMD mkpart primary linux-swap 65% 67%
# /home
echo "Making partition for Home..."
PARTED_CMD mkpart primary ext4 67% 100%

# The disk names are determined by the order they were created above.
BOOT_DISK="${DISK}"1
ROOT_DISK="${DISK}"2
SWAP_DISK="${DISK}"3
HOME_DISK="${DISK}"4

# format partitions
echo "Formatting Boot partition..."
mkfs.fat -F32 /dev/$BOOT_DISK
echo "Formatting Root partition..."
mkfs.ext4 /dev/$ROOT_DISK
echo "Formatting Swap partition..."
mkswap /dev/$SWAP_DISK
swapon /dev/$SWAP_DISK
echo "Formatting Home partition..."
mkfs.ext4 /dev/$HOME_DISK

###################################
# mount the filesystem structure. #
###################################
echo "Mounting Root to /mnt"
mount /dev/$ROOT_DISK /mnt
mkdir /mnt/boot
echo "Mounting Boot to /mnt/boot"
mount /dev/$BOOT_DISK /mnt/boot
mkdir /mnt/home
echo "Mounting Home to /mnt/home"
mount /dev/$HOME_DISK /mnt/home
###################################

##################################################################
# make the Brazilian server the first of the list in mirrorlist. #
##################################################################
echo "Setting brazilian server as the first in the mirrorlist..."
grep 'archlinux-br\.mirror' -B 1 /etc/pacman.d/mirrorlist > tmp1
grep -v 'archlinux-br\.mirror' /etc/pacman.d/mirrorlist > tmp2
cat tmp2 >> tmp1
mv tmp1 /etc/pacman.d/mirrorlist
rm tmp2
################################################################

echo "Installing the base package..."
yes | pacstrap /mnt base
genfstab -U /mnt >> /mnt/etc/fstab

echo "chrooting to /mnt..."
arch-chroot /mnt

echo "Setting the local time and language..."
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

sed 's/#en_US\.UTF-8/en_US\.UTF-8/g' -i /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "myarch" > /etc/hostname
echo "127.0.1.1	myarch.localdoman	myarch" >> /etc/hosts

# TODO: install wireless network stuff?

echo "Installing expect program..."
yes | pacman -S expect
echo "Setting root password..."
/usr/bin/expect <<EOD
spawn passwd
expect "New password:"
send "${ROOT_PWD}\n"
expect "Retype new password:"
send "${ROOT_PWD}\n"
EOD
echo ""

echo "Installing GRUB..."
yes | pacman -S grub
#TODO: add boot partition name
grub-install --target=i386-pc /dev/$BOOT_DISK
