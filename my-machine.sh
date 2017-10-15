#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

print_usage() {
	echo ""
	echo "USAGE: VBOX=<path_to_vbox_bin> PYTHON=<path_to_python> ROOT_PWD=<root_pwd> ./my-machine <arch_iso> <vboxadd_iso>"
}

function verify_var_set() {
	if [ -z "$1" ]; then
		echo "Variable $2 was not set."
		print_usage
		exit 1
	fi
}

verify_var_set "$VBOX" "VBOX"
verify_var_set "$PYTHON" "PYTHON"
verify_var_set "$ROOT_PWD" "ROOT_PWD"

# Add VBox folder with bin files to path.
PATH="$PATH:$VBOX:$PYTHON"

function exit_if_file_doesnt_exist() {
	file=$1
	if [ ! -f "$file" ]; then
		echo "File $file not found. Exiting."
		print_usage
		exit 1
	fi
}

ARCH_ISO_PATH=$1
if [ -z "$ARCH_ISO_PATH" ]; then
	echo "Arch .iso file path not specified."
	print_usage
	exit 1
fi

VBOXADD_ISO_PATH=$2
if [ -z "$VBOXADD_ISO_PATH" ]; then
	echo "VirtualBox Guest Additions .iso file path not specified."
	VBOXADD_ISO_PATH="C:\\Program Files\\Oracle\\VirtualBox\\VBoxGuestAdditions.iso"
	echo "Using path: $VBOXADD_ISO_PATH"
fi

exit_if_file_doesnt_exist "$ARCH_ISO_PATH"
exit_if_file_doesnt_exist "$VBOXADD_ISO_PATH"

function exit_if_exists() {
	name=$1
	type=$2
	res=$(VBoxManage list "$type" | grep "$name") 
	if [ ! -z "$res" ]; then
		echo "$type '$name' already exists. Remove/Rename it before proceeding."
		print_usage
		exit 1
	fi
}

VM_NAME='MyArch-64bits'
DISK_NAME="${VM_NAME}.vid"

exit_if_exists $VM_NAME 'vms'
exit_if_exists $DISK_NAME 'hdds'


DISK_SIZE=32768 # 32GB
OS_TYPE='ArchLinux_64'
RAM=4096 # 4GB
VRAM=128 

# Create dynamic disk
VBoxManage createvm --name $VM_NAME --ostype $OS_TYPE --register
VBoxManage createhd --filename $DISK_NAME --size $DISK_SIZE 

# SATA controller with the dynamic disk attached
SATA_CONTROLLER="SATA_Controller"
VBoxManage storagectl $VM_NAME --name $SATA_CONTROLLER --add sata --controller IntelAHCI
VBoxManage storageattach $VM_NAME --storagectl $SATA_CONTROLLER --port 0 --device 0 --type hdd --medium $DISK_NAME

# IDE controller to attach the Arch ISO and VBox Additions ISO.
IDE_CONTROLLER="IDE_Controller"
VBoxManage storagectl $VM_NAME --name $IDE_CONTROLLER --add ide
VBoxManage storageattach $VM_NAME --storagectl $IDE_CONTROLLER --port 0 --device 0 --type dvddrive --medium "$ARCH_ISO_PATH"

VBoxManage modifyvm $VM_NAME --boot1 dvd --boot2 disk
VBoxManage modifyvm $VM_NAME --memory $RAM --vram $VRAM 

VBoxManage startvm $VM_NAME

echo "Waiting 5 seconds..."
sleep 5
echo "Sending 'ENTER' key to $VM_NAME."
# 1c: pressing ENTER key; 9c: releasing ENTER key.
VBoxManage controlvm $VM_NAME keyboardputscancode 1c 9c

echo "Waiting 30s for VM to finish booting..."
sleep 30

# remove the Arch ISO so that the VM will use the disk when booting.
#VBoxManage storageattach $VM_NAME --storagectl $IDE_CONTROLLER --port 0 --device 0 --type dvddrive --medium "$VBOXADD_ISO_PATH"

# Send keyboard keys to VM.
function send_keys_to_vm() {
	for c in $(python $DIR/echo_scancode.py $1); do
		VBoxManage controlvm $VM_NAME keyboardputscancode $c
		sleep 0.01
	done
}

echo "Making VM download the setup-arch.sh script."
github_raw="raw.githubusercontent.com/brunodea/my-machine/master"
# ! is interpreted as ENTER by the echo_scancode.py script.
send_keys_to_vm "wget ${github_raw}/setup-arch.sh && wget ${github_raw}/setup-arch-step2.sh && chmod +x setup-arch.sh && ./setup-arch.sh ${ROOT_PWD} !"

#FIRST_SNAPSHOT_NAME="my-machine-setup"
# Snapshot after the setup is done.
#VBoxManage snapshot $VM_NAME take $FIRST_SNAPSHOT_NAME

# To get back to a snapshot
#VBoxManage snapshot $VM_NAME restore $FIRST_SNAPSHOT_NAME

