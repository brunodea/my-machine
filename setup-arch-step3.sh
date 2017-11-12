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
# we do this so the user won't be prompted for password with pacman and, specially, yaourt.
echo "wheel ALL=(ALL) ALL" >> sudoers
echo "Cmnd_Alias PACMAN = /usr/bin/pacman, /usr/bin/yaourt" >> sudoers
echo "wheel ALL=(ALL) NOPASSWD: PACMAN" >> sudoers
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
#-------------------------------------------------
# Install packages
#-------------------------------------------------
install_pkg xfce4-whiskermenu-plugin
#image viewer
install_pkg ristretto
install_pkg wget
install_pkg git
install_pkg gvim # or should I try neovim?
install_pkg openssh
install_pkg gnupg
# install yaourt
install_pkg pkg-config
install_pkg fakeroot
git clone https://aur.archlinux.org/package-query.git
cd package-query
makepkg -si --noconfirm
pacman -U *.pkg.* --noconfirm
cd ..
git clone https://aur.archlinux.org/yaourt.git
cd yaourt
makepkg -si --noconfirm
pacman -U *.pkg.* --noconfirm
cd ..
#-------------------------------------------------
# We need VBoxAdditions because o GPG config
# We need GPG config because I want to install stuff with yaourt
install_pkg virtualbox-guest-utils
systemctl enable vboxservice.service
#-------------------------------------------------
# Configure GPG
#-------------------------------------------------
echo "Configuring GPG..."
# set default pinentry used by GPG to pinentry-tty.
ln -sf /usr/bin/pinentry-tty /usr/bin/pinentry
echo "Setting GPG_CONFIG property to START"
VBoxControl guestproperty set "GPG_CONFIG" "START"
echo "Waiting GPG_CONFIG property to be DONE..."
VBoxControl guestproperty wait "GPG_CONFIG" "DONE"
#-------------------------------------------------
# Install applications
#-------------------------------------------------
# configure things as user
su - $USER
echo "keyserver-options auto-key-retrieve" > ~/.gnupg/gpg.conf
gpg --send-keys $(gpg -k | grep $USER -B 1 | grep -v $USER | awk '{print $1}')
gpgconf --reload gpg-agent
function yaourt_install {
	NOCONFIRM=1 BUILD_NOCONFIRM=1 EDITFILES=0 yaourt -S ${@:1} --noconfirm
}

yaourt_install firefox-nightly

PRJ_DIR=~/prj
mkdir $PRJ_DIR
cd $PRJ_DIR
# Download all the custom configurations.
git clone https://github.com/brunodea/general-cfgs.git
GEN_CFG=$PRJ_DIR/general-cfgs
# Configure XFCE
cd ~/.config/xfce4/xfconf/xfce-perchannel-xml
ln -sf $GEN_CFG/xfce4/xfconf/xfce-perchannel-xml/*.xml .

cd ~
# Configure .bashrc
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
ln -sf $GEN_CFG/.bashrc .
ln -sf $GEN_CFG/.vimrc .
ln -sf $GEN_CFG/.face .


# go back to root
exit
#-------------------------------------------------
# Only enable the DM at the end so it doesn't "get in the way".
# Also, it should only be enabled after installing a Desktop Environment.
systemctl enable lxdm

# TODO: set vbox property for "reboot finish" in the HOOK provided by LXDM.

# TODO: when configuring stuff, do it as $USER instead of root.
# TODO: in xfce4-panel.xml replace /home to /home/$USER via sed.
# TODO: in xfce4-desktop.xml replace /home to /home/$USER via sed.
# TODO: move default_wallpaper to /home/$USER/wallpapers
# TODO: download general-cfgs and make the proper soft links
# TODO: install alsamixer
# TODO: .face has to have r-- permission and /home/bruno has to have r-x permissions.
# TODO: automate ssh-key generation
# TODO: add file to desktop with name TODO with stuff that need to be manually done (e.g. add the SSH key to github).

# TODO FILE:
# TODO: add to the TODO file "gpg --full-gen-key" and installation of all applications via yaourt
# TODO: add keyserver-options auto-key-retrieve to gpg.conf

echo "========== STEP 3 SUCCESS =========="
