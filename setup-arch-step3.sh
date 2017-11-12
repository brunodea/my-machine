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
install_pkg wget
install_pkg git
install_pkg gvim # or should I try neovim?
install_pkg openssh
install_pkg gnupg
# install yaourt
install_pkg pkg-config
install_pkg fakeroot

function run_as_user {
	sudo -H -u $USER bash -c "cd ~ && ${@}"
}

function install_yaourt {
	run_as_user "git clone https://aur.archlinux.org/package-query.git && \
		cd package-query && \
		makepkg -si --noconfirm && \
		sudo pacman -U *.pkg.* --noconfirm && \
		cd .. && \
		git clone https://aur.archlinux.org/yaourt.git && \
		cd yaourt && \
		makepkg -si --noconfirm && \
		sudo pacman -U *.pkg.* --noconfirm && \
		cd .. && \
		rm -rf package-query && \
		rm -rf yaourt"
}

install_yaourt
#-------------------------------------------------
# We need VBoxAdditions because o GPG config
# We need GPG config because I want to install stuff with yaourt
install_pkg virtualbox-guest-utils
systemctl enable --now vboxservice.service
#-------------------------------------------------
# Configure GPG
#-------------------------------------------------
echo "Configuring GPG..."
# set default pinentry used by GPG to pinentry-tty.
ln -sf /usr/bin/pinentry-tty /usr/bin/pinentry
echo "Setting GPG_CONFIG property to START"
VBoxControl guestproperty set "GPG_CONFIG_START" "True"
# gpg config must be done as user.
# because gpg waits for stdin and the stdin comes from the HOST,
# we don't need to wait for some signal that the configuration was done.
run_as_user "gpg --full-gen-key"
#-------------------------------------------------
# Install applications
#-------------------------------------------------
# configure things as user

function yaourt_install {
	NOCONFIRM=1 BUILD_NOCONFIRM=1 EDITFILES=0 yaourt -S ${@} --noconfirm
}

function config_system {
	run_as_user "echo \"Started to configure system\" && \
	echo \"Configuring GPG keys...\" && \
	echo \"keyserver-options auto-key-retrieve\" > ~/.gnupg/gpg.conf && \ && \
	gpg --send-keys $(gpg -k | grep $USER -B 1 | grep -v $USER | awk '{print $1}') && \ && \
	gpgconf --reload gpg-agent && \ && \
	echo \"Installing packages from yaourt...\" && \
	yaourt_install firefox-nightly && \
	yaourt_install lxdm-themes && \
	echo \"Installing custom configurations from general-cfgs...\" && \
	PRJ_DIR=/home/$USER/prj && \
	# Download all the custom configurations. && \
	mkdir $PRJ_DIR && \
	cd $PRJ_DIR && \
	git clone https://github.com/brunodea/general-cfgs.git && \
	GEN_CFG=$PRJ_DIR/general-cfgs && \
	# Configure XFCE && \
	cd ~/.config/xfce4/xfconf/xfce-perchannel-xml && \
	cp $GEN_CFG/xfce4/xfconf/xfce-perchannel-xml/*.xml . && \
	sed -i \"s|\$USER|$USER|g\" * && \
	# Configure .bashrc && \
	# Permissions required by LXDM && \
	wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash && \
	wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh && \
	mv git-completion.bash .git-completion.bash && \
	mv git-prompt.sh .git-prompt.sh && \
	mkdir wallpapers && \
	cp $GEN_CFG/default_wallpaper.jpg wallpapers/ && \
	cp $GEN_CFG/login_wallpaper.jpg wallpapers/ && \
	cp $GEN_CFG/.face . && \
	chmod 755 wallpapers && \
	chmod 755 wallpapers/default_wallpaper.jpg && \
	chmod 755 wallpapers/login_wallpaper.jpg && \
	chmod 400 .face && \
	ln -sf $GEN_CFG/.bashrc . && \
	ln -sf $GEN_CFG/.vimrc ."
}

config_system

#-------------------------------------------------
# Only enable the DM at the end so it doesn't "get in the way".
# Also, it should only be enabled after installing a Desktop Environment.
systemctl enable lxdm

# TODO: set vbox property for "reboot finish" in the HOOK provided by LXDM.

# TODO: install alsamixer
# TODO: automate ssh-key generation
# TODO: add file to desktop with name TODO with stuff that need to be manually done (e.g. add the SSH key to github).

echo "========== STEP 3 SUCCESS =========="
