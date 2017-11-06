#!/bin/bash

USER=$1
USER_PWD=$2

echo "========== STEP 3 START =========="
# Actually customizing ARCH.

echo "Initializing NetworkManager service..."
# Start NetworkManager service at every boot.
systemctl enable --now NetworkManager.service

# fix Failed to start Load Kernel Modules.
pacman -S linux-headers --noconfirm
pacman -S sudo --noconfirm

##################################################
# Make wheel group a sudoer.
##################################################
cp /etc/sudoers .
wheel_su="%wheel ALL=(ALL) ALL"
sed -i "s|# $wheel_su|$wheel_su|" sudoers
visudo -c -f sudoers
cp sudoers /etc/sudoers
##################################################

echo "Setting up user..."
# Create user and add to the wheel group.
useradd -m -G wheel $USER
echo -e "${USER_PWD}\n${USER_PWD}" | passwd $USER

echo "Installing VBoxAdditions..."
pacman -S virtualbox-guest-utils --noconfirm

echo "========== STEP 3 SUCCESS =========="
