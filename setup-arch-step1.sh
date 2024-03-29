#!/bin/bash

echo "========== STEP 1 START =========="

# if anything fails, abort!
set -e

ROOT_PWD="$1"
if [ -z "$ROOT_PWD" ]; then
	echo "Aborting. Missing root password."
	exit 1
fi
HOSTNAME="$2"

echo "Setting system clock..."
# ensure the system clock is accurate
timedatectl set-ntp true

echo "Figuring out disk name..."
# figure out how the disk is called (i.e., sda, sdb, sdc, ...) -- will probably be sda.
DISK=$(fdisk -l | grep /dev/sd | awk '{print $2}' | sed 's/\/dev\///' | sed 's/://')

# create partitions 
function partedcmd() {
	parted -a optimal -s /dev/${DISK} ${@:1}
}

echo "Making partion label MBR..."
partedcmd mklabel msdos
echo "Making partition for Boot..."
partedcmd mkpart primary ext4 1MiB 300MiB
partedcmd set 1 boot on
# /
echo "Making partition for Root..."
partedcmd mkpart primary ext4 300MiB 65%
# /swap
echo "Making partigion for Swap..."
partedcmd mkpart primary linux-swap 65% 67%
# /home
echo "Making partition for Home..."
partedcmd mkpart primary ext4 67% 100%

# The disk names are determined by the order they were created above.
BOOT_DISK="${DISK}"1
ROOT_DISK="${DISK}"2
SWAP_DISK="${DISK}"3
HOME_DISK="${DISK}"4

# format partitions
echo "Formatting Boot partition..."
mkfs.ext4 /dev/$BOOT_DISK
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
#echo "Setting brazilian server as the first in the mirrorlist..."
#grep 'archlinux-br\.mirror' -B 1 /etc/pacman.d/mirrorlist > tmp1
#grep -v 'archlinux-br\.mirror' /etc/pacman.d/mirrorlist > tmp2
#cat tmp2 >> tmp1
#mv tmp1 /etc/pacman.d/mirrorlist
#rm tmp2
################################################################

echo "Installing the base package..."
yes | pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

# move the step2 script to the /root folder and run it.
# after everything is done, remove the script file and the .bashrc file.
cp setup-arch-step* /mnt/root

echo "========== STEP 1: SUCCESS =========="
echo "Running STEP 2..."
arch-chroot /mnt /bin/bash -c "chmod +x /root/setup-arch-step2.sh"
arch-chroot /mnt /bin/bash -c "./root/setup-arch-step2.sh ${DISK} ${ROOT_PWD} ${HOSTNAME} 2>&1 | tee /root/step2.out"
if [ ! $? = 0 ]; then
	echo "========== STEP 2: FAILED =========="
	exit 1
fi
