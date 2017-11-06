#!/bin/bash

#if anything fails, abort!
set -e

BOOT_DISK=$1
ROOT_PWD=$2

echo "Setting the local time and language..."
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

sed 's/#en_US\.UTF-8/en_US\.UTF-8/g' -i /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "myarch" > /etc/hostname
echo "127.0.1.1	myarch.localdoman	myarch" >> /etc/hosts

# TODO: install wireless network stuff?

echo "Setting root password..."
echo -e "${ROOT_PWD}\n${ROOT_PWD}" | passwd root

echo "Installing GRUB..."
yes | pacman -S grub
grub-install --target=i386-pc /dev/$BOOT_DISK
grub-mkconfig -o /boot/grub/grub.cfg

# for intel microcode updates
pacman -S intel-ucode --noconfirm
# install NetworkMananger
pacman -S networkmanager --noconfirm
# fix grub
grub-mkconfig -o /boot/grub/grub.cfg
