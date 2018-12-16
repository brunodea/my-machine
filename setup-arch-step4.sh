#!/bin/bash

set -e

echo "========== STEP 4 START =========="

USER=$1

# This script should be run as $USER

# install yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
sudo pacman -U *.pkg.* --noconfirm
cd .. && rm -rf yay

# install package using yay
function yay_install {
	NOCONFIRM=1 BUILD_NOCONFIRM=1 EDITFILES=0 yay -S ${@} --noconfirm
}

echo "Started to configure system"
echo "Configuring GPG keys..."

echo "Setting GPG_CONFIG property to START"
sudo VBoxControl guestproperty set "GPG_CONFIG_START" "True"
gpg --full-gen-key

echo "keyserver-options auto-key-retrieve" > ~/.gnupg/gpg.conf
gpg --send-keys $(gpg -k | grep $USER -B 1 | grep -v $USER | awk '{print $1}')
gpgconf --reload gpg-agent
echo "Installing packages using yay..."
yay_install firefox-nightly
yay_install lxdm-themes
yay_install zeal
yay_install hexchat
yay_install xfce4-datetime-plugin
yay_install curl
yay_install python
yay_install cmake
yay_install alsa-utils
yay_install tmux
yay_install neovim

# installing pip and adding support for it on neovim just because of
# the Denite plugin.
yay_install python-pip
sudo pip3 install --upgrade neovim

# install vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# tmux cool conf
cd "/home/$USER"
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local . # default local conf

# adding this config, because .bashrc expects to find the rust-src
# in order to set the RUST_SRC_PATH environment variable
echo "Installing RUST nightly"
export CARGO_HOME="/home/${USER}/.rust/cargo"
export RUSTUP_HOME="/home/${USER}/.rust/rustup"
export PATH="$PATH:$CARGO_HOME/bin"
mkdir -p "$CARGO_HOME"
mkdir -p "$RUSTUP_HOME"
rust_installer=rust_installer.sh
curl https://sh.rustup.rs -sSf > $rust_installer
chmod +x $rust_installer
./$rust_installer -y # install with defaults
rm $rust_installer
rustup install nightly
rustup default nightly
rustup component add rust-src
rustup component add rustfmt-preview --toolchain nightly
cargo +nightly install racer
#FIXME: error: no such file (folder bash_completion.d doesn't exist).
#              shouldn't run this as sudo in this step. Find another way.
#rustup completions bash > /etc/bash_completion.d/rustup.bash-completion

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
ln -sf $GEN_CFG/.bash_profile .
ln -sf $GEN_CFG/.tmux.conf.local .

if [ ! -d ~/.config/nvim ]; then
	mkdir -p ~/.config/nvim
fi
ln -sf $GEN_CFG/init.vim ~/.config/nvim/init.vim

mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts && curl -fLo "Droid Sans Mono for Powerline Nerd Font Complete.otf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf

#System upgrade
yay -Syu --devel --timeupdate --noconfirm

cd ~
sudo VBoxControl guestproperty set "ENABLE_LXDM" "True"
# Only enable the DM at the end so it doesn't "get in the way".
# Also, it should only be enabled after installing a Desktop Environment.
sudo systemctl enable lxdm

echo "========== STEP 4 SUCCESS =========="

sudo VBoxControl guestproperty wait "FINISH_SETUP"
reboot
