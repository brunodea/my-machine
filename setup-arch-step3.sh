#!/bin/bash

echo "========== STEP 3 START =========="

#vbox_add=$(ls /dev/disks/by-label/VBOXADDITIONS*)
#
#mount $vbox_add /mnt
#./mnt/VBoxLinuxAdditions.run
echo "Installing VBoxAdditions..."
pacman -S virtualbox-guest-utils --noconfirm
