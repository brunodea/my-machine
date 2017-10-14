#!/bin/bash

# Usage: VBOX=<path_to_vbox_bin> my-machine <arch_iso>

ARCH_ISO_PATH=$1
if [ -z $ARCH_ISO_PATH ]; then
	echo "Arch .iso file path not specified."
	exit 1
fi

if [ -z $VBOX ]; then
	echo "Path to the bin files of Virtual Box was not set."
	exit 1
fi

PATH="$PATH:$VBOX"

function exit_if_exists() {
	name=$1
	type=$2
	res=$(VBoxManage list $type | grep $name) 
	if [ ! -z $res ]; then
		echo "$type '$name' already exists. Remove/Rename it before proceeding."
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
VBoxManage createhd --filename $DISK_NAME --size $DISK_SIZE 
VBoxManage createvm --name $VM_NAME --ostype $OS_TYPE --register

# SATA controller with the dynamic disk attached
VBoxManage storagectl $VM_NAME --name "SATA Controller" --add sata -- controller IntelAHCI
VBoxManage storageattach $VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $DISK_NAME

# IDE controller to attach the install ISO.
VBoxManage storagectl $VM_NAME --name "IDE Controller" --add ide
VBoxManage storageattach $VM_NAME --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $ARCH_ISO_PATH

VBoxManage modifyvm $VM_NAME --ioapic on
# First boot has to be via DVD, later it should be changed to hdd: TODO.
VBoxManage modifyvm $VM_NAME --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm $VM_NAME --memory $RAM --vram $VRAM 
VBoxManage modifyvm $VM_NAME --natnet default

VBoxHeadless -s $VM_NAME

# TODO: configure the OS

#eject the DVD
#VBoxManage storageattach $VM_NAME --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium none

FIRST_SNAPSHOT_NAME="my-machine-setup"
# Snapshot after the setup is done.
VBoxManage snapshot $VM_NAME take $FIRST_SNAPSHOT_NAME

# To get back to a snapshot
#VBoxManage snapshot $VM_NAME restore $FIRST_SNAPSHOT_NAME

