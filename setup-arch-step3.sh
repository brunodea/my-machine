#!/bin/bash

USER=$1
USER_PWD=$2

echo "========== STEP 3 START =========="
# Actually customizing ARCH.

echo "Initializing NetworkManager service..."
# Start NetworkManager service at every boot.
systemctl enable --now NetworkManager.service

function install_pkg() {
	pacman -S ${@:1} --noconfirm
}

# fix Failed to start Load Kernel Modules.
install_pkg linux-headers
install_pkg sudo

##################################################
# Make wheel group a sudoer.
##################################################
echo "Setting up user..."
cp /etc/sudoers .
wheel_su="%wheel ALL=(ALL) ALL"
sed -i "s|# $wheel_su|$wheel_su|" sudoers
visudo -c -f sudoers
cp sudoers /etc/sudoers
# Create user and add to the wheel group.
useradd -m -G wheel $USER
echo -e "${USER_PWD}\n${USER_PWD}" | passwd $USER
##################################################

##################################################
# Configure graphics.
##################################################
# Using XORG because XFCE currently doesn't support Wayland.
echo "Configuring graphics..."
install_pkg xorg
# Install the Display Manager.
install_pkg lxdm
install_pkg xfce4
# Make default session to be XFCE.
sess="session=/usr/bin"
sed -i "s|# $sess|$sess|" /etc/lxdm/lxdm.conf
sed -i "s|$sess/startlxde|$sess/startxfce4|" /etc/lxdm/lxdm.conf
##################################################

echo "Installing VBoxAdditions..."
install_pkg virtualbox-guest-utils
systemctl enable vboxservice.service
# Only enable the DM at the end so it doesn't "get in the way".
# Also, it should only be enabled after installing a Desktop Environment.
systemctl enable lxdm

echo "========== STEP 3 SUCCESS =========="
