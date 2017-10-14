#!/bin/bash

print_usage() {
	echo ""
	echo "USAGE: VBOX=<path_to_vbox_bin> ./my-machine <arch_iso> <vboxadd_iso>"
}

if [ -z "$VBOX" ]; then
	echo "Path to the bin files of Virtual Box was not set."
	print_usage
	exit 1
fi

# Add VBox folder with bin files to path.
PATH="$PATH:$VBOX"

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
VBoxManage storageattach $VM_NAME --storagectl $IDE_CONTROLLER --port 0 --device 1 --type dvddrive --medium "$VBOXADD_ISO_PATH"

## First boot has to be via DVD, later it should be changed to hdd: TODO.
VBoxManage modifyvm $VM_NAME --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm $VM_NAME --memory $RAM --vram $VRAM 

VBoxManage startvm $VM_NAME 

#FIRST_SNAPSHOT_NAME="my-machine-setup"
# Snapshot after the setup is done.
#VBoxManage snapshot $VM_NAME take $FIRST_SNAPSHOT_NAME

# To get back to a snapshot
#VBoxManage snapshot $VM_NAME restore $FIRST_SNAPSHOT_NAME

