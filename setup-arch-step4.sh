#!/bin/bash

set -e

echo "========== STEP 4 START =========="

USER=$1

# This script should be run as $USER

# install yaourt
git clone https://aur.archlinux.org/package-query.git
cd package-query
makepkg -si --noconfirm
sudo pacman -U *.pkg.* --noconfirm
cd ..
git clone https://aur.archlinux.org/yaourt.git
cd yaourt
makepkg -si --noconfirm
sudo pacman -U *.pkg.* --noconfirm
cd ..
rm -rf package-query
rm -rf yaourt

# install package from yaourt
function yaourt_install {
	NOCONFIRM=1 BUILD_NOCONFIRM=1 EDITFILES=0 yaourt -S ${@} --noconfirm
}

echo "Started to configure system"
echo "Configuring GPG keys..."

echo "Setting GPG_CONFIG property to START"
sudo VBoxControl guestproperty set "GPG_CONFIG_START" "True"
gpg --full-gen-key

echo "keyserver-options auto-key-retrieve" > ~/.gnupg/gpg.conf
gpg --send-keys $(gpg -k | grep $USER -B 1 | grep -v $USER | awk '{print $1}')
gpgconf --reload gpg-agent
echo "Installing packages from yaourt..."
yaourt_install firefox-nightly
yaourt_install lxdm-themes
yaourt_install zeal
yaourt_install hexchat
echo "Installing custom configurations from general-cfgs..."
PRJ_DIR=/home/$USER/prj
# Download all the custom configurations.
mkdir $PRJ_DIR
cd $PRJ_DIR
git clone https://github.com/brunodea/general-cfgs.git
GEN_CFG=$PRJ_DIR/general-cfgs
cp -r $GEN_CFG/hexchat/ ~/.config
cp -r $GEN_CFG/xfce4/ ~/.config
cd ~/.config/xfce4/xfconf/xfce-perchannel-xml
sed -i "s|\$USER|$USER|g" *.xml
cd ~
# Configure .bashrc
# Permissions required by LXDM
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
mv git-completion.bash .git-completion.bash
mv git-prompt.sh .git-prompt.sh
mkdir wallpapers
cp $GEN_CFG/default_wallpaper.jpg wallpapers/
cp $GEN_CFG/login_wallpaper.jpg wallpapers/
cp $GEN_CFG/.face .
chmod 755 wallpapers
chmod 755 wallpapers/default_wallpaper.jpg
chmod 755 wallpapers/login_wallpaper.jpg
chmod 400 .face
ln -sf $GEN_CFG/.bashrc .
ln -sf $GEN_CFG/.vim .

sudo VBoxControl guestproperty set "ENABLE_LXDM" "True"
# Only enable the DM at the end so it doesn't "get in the way".
# Also, it should only be enabled after installing a Desktop Environment.
sudo systemctl enable lxdm

echo "========== STEP 4 SUCCESS =========="

sudo VBoxControl guestproperty wait "FINISH_SETUP"
reboot
