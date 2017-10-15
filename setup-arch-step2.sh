#!/bin/bash

#if anything fails, abort!
set -e

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
grub-install --target=i386-pc /dev/$BOOT_DISK
grub-mkconfig -o /boot/grub/grub.cfg

# for intel microcode updates
yes | pacman -S intel-ucode
grub-mkconfig -o /boot/grub/grub.cfg