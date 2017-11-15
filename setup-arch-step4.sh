#!/bin/bash

USER=$1

echo "========== STEP 4 START =========="

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
# Configure GPG
#-------------------------------------------------
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

function config_system {
	yaourt_install_file=/home/$USER/yaourt_install.sh
	echo "#!/bin/bash" > $yaourt_install_file
	echo "function yaourt_install { \
		NOCONFIRM=1 BUILD_NOCONFIRM=1 EDITFILES=0 yaourt -S ${@} --noconfirm \
	}" >> $yaourt_install_file

	run_as_user "source /home/$USER/yaourt_install.sh && \
	echo \"Started to configure system\" && \
	echo \"Configuring GPG keys...\" && \
	echo \"keyserver-options auto-key-retrieve\" > ~/.gnupg/gpg.conf && \
	gpg --send-keys $(gpg -k | grep $USER -B 1 | grep -v $USER | awk '{print $1}') && \
	gpgconf --reload gpg-agent && \
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

	rm $yaourt_install_file
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

echo "========== STEP 4 SUCCESS =========="
