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
# we do this so the user won't be prompted for password with pacman and, specially, yay.
echo "%wheel ALL=(ALL) ALL" >> sudoers
echo "Cmnd_Alias PACMAN = /usr/bin/pacman, /usr/bin/yay, /usr/bin/VBoxControl" >> sudoers
echo "%wheel ALL=(ALL) NOPASSWD: PACMAN" >> sudoers
visudo -c -f sudoers
mv sudoers /etc/sudoers
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
# Configure LXDM
sed -i '/session=/c\session=/usr/bin/startxfce4' /etc/lxdm/lxdm.conf
sed -i '/bg=/c\bg=' /etc/lxdm/lxdm.conf
sed -i "s|bg=|bg=\/home\/$USER\/wallpapers\/login_wallpaper.jpg|g" /etc/lxdm/lxdm.conf
sed -i '/theme=/c\theme=ArchlinuxFull' /etc/lxdm/lxdm.conf
sed -i '/bottom_pane=/c\bottom_pane=0' /etc/lxdm/lxdm.conf
# In order for LXDM to be able to get the background and .face images the home folder
# has to have r-x permission for 'others'
chmod 705 /home/$USER
##################################################
#-------------------------------------------------
# Install packages
#-------------------------------------------------
install_pkg xfce4-whiskermenu-plugin
#image viewer
install_pkg ristretto
install_pkg curl
install_pkg git
install_pkg openssh
install_pkg gnupg
# for installing yay
install_pkg pkg-config
install_pkg fakeroot

#-------------------------------------------------
# We need VBoxAdditions because o GPG config
# We need GPG config because I want to install stuff with yay
install_pkg virtualbox-guest-utils
systemctl enable --now vboxservice.service
# set default pinentry used by GPG to pinentry-tty.
ln -sf /usr/bin/pinentry-tty /usr/bin/pinentry

# since step4 should be run as USER, we move it to the user's folder
# and change its ownership
mv /root/setup-arch-step4.sh /home/$USER/
chown $USER:$USER /home/$USER/setup-arch-step4.sh

echo "Setting STEP_4_START to True"
VBoxControl guestproperty set "STEP_4_START" "True"

# TODO: set vbox property for "reboot finish" in the HOOK provided by LXDM.

# TODO: install alsamixer
# TODO: automate ssh-key generation
# TODO: add file to desktop with name TODO with stuff that need to be manually done (e.g. add the SSH key to github).

echo "========== STEP 3 SUCCESS =========="
reboot
