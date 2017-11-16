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
yaourt_install xfce4-datetime-plugin
yaourt_install rustup 

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
ln -sf $GEN_CFG/.vimrc .


mkdir .vim
cd .vim
mkdir autoload
git clone https://github.com/tpope/vim-pathogen.git
ln -sf /home/$USER/.vim/autoload/vim-pathogen/autoload/pathogen.vim autoload/pathogen.vim
mkdir bundle
cd bundle
#indentLine
git clone https://github.com/Yggdroot/indentLine
#nerdtree
git clone https://github.com/scrooloose/nerdtree.git ~/.vim/bundle/nerdtree
#oceanic-next
git clone https://github.com/mhartington/oceanic-next
#rust.vim
git clone --depth=1 https://github.com/rust-lang/rust.vim.git ~/.vim/bundle/rust.vim
#denite.nvim
#TODO: install python3 for this plugin.
#git clone https://github.com/Shougo/denite.nvim
#vim-airline
git clone https://github.com/vim-airline/vim-airline
#vim-autoformat
git clone https://github.com/Chiel92/vim-autoformat
#vim-devicons
git clone https://github.com/ryanoasis/vim-devicons
#vim-exchange
# TODO: do I really want this?
#git clone git://github.com/tommcdo/vim-exchange.git
#vim-fugitive
git clone https://github.com/tpope/vim-fugitive
#vim-numbertoggle
git clone https://github.com/jeffkreeftmeijer/vim-numbertoggle
#vimproc.vim
git clone https://github.com/Shougo/vimproc.vim
# TODO: configure YCM
#YCM-Generator
git clone https://github.com/rdnetto/YCM-Generator
#YouCompleteMe
git clone https://github.com/Valloric/YouCompleteMe
#zeavim.vim
# TODO: fix config as per their README.
git clone https://github.com/KabbAmine/zeavim.vim

echo "#!/bin/bash" > update_all.sh
echo "for d in /home/$USER/.vim/bundle/*; do" >> update_all.sh
echo "cd $d" >> update_all.sh
echo "git pull origin master" >> update_all.sh
echo "git submodule update --recursive --remote" >> update_all.sh
echo "cd .." >> update_all.sh
echo "done" >> update_all.sh

cd ~
sudo VBoxControl guestproperty set "ENABLE_LXDM" "True"
# Only enable the DM at the end so it doesn't "get in the way".
# Also, it should only be enabled after installing a Desktop Environment.
sudo systemctl enable lxdm

echo "========== STEP 4 SUCCESS =========="

sudo VBoxControl guestproperty wait "FINISH_SETUP"
reboot
