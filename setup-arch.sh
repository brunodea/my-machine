#!/bin/bash

# if anything fails, abort!
set -e

ROOT_PWD="$1"
if [ -z "$ROOT_PWD" ]; then
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
function partedcmd() {
	parted -a optimal -s /dev/${DISK} ${@:1}
}

echo "Making partion label MBR..."
partedcmd mklabel msdos
echo "Making partition for Boot..."
partedcmd mkpart primary ext4 1MiB 100MiB
partedcmd set 1 boot on
# /
echo "Making partition for Root..."
partedcmd mkpart primary ext4 100MiB 65%
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

# in order to run the step2 of the script, we have to call it from the .bashrc
# file of the root user of our machine, everything after the change root line in the
# current script will only be performed after leaving the new root.

# move the step2 script to the /root folder and run it.
# after everything is done, remove the script file and the .bashrc file.
mv setup-arch-step2.sh /mnt/root
echo "#!/bin/bash" > /mnt/root/.bashrc
echo "chmod +x setup-arch-step2.sh" > /mnt/root/.bashrc
echo "./setup-arch-step2.sh ${ROOT_PWD}" > /mnt/root/.bashrc
echo "rm /root/setup-arch-step2.sh" > /mnt/root/.bashrc
echo "rm /root/.bashrc" > /mnt/root/.bashrc

echo "chrooting to /mnt..."
arch-chroot /mnt
