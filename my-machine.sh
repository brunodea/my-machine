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

exit_if_exists "$VM_NAME" 'vms'
exit_if_exists $DISK_NAME 'hdds'


DISK_SIZE=32768 # 32GB
OS_TYPE='ArchLinux_64'
RAM=4096 # 4GB
VRAM=128 

# Create dynamic disk
VBoxManage createvm --name "$VM_NAME" --ostype $OS_TYPE --register
VBoxManage createhd --filename $DISK_NAME --size $DISK_SIZE 

# SATA controller with the dynamic disk attached
SATA_CONTROLLER="SATA_Controller"
VBoxManage storagectl "$VM_NAME" --name $SATA_CONTROLLER --add sata --controller IntelAHCI
VBoxManage storageattach "$VM_NAME" --storagectl $SATA_CONTROLLER --port 0 --device 0 --type hdd --medium $DISK_NAME

# IDE controller to attach the Arch ISO and VBox Additions ISO.
IDE_CONTROLLER="IDE_Controller"
VBoxManage storagectl "$VM_NAME" --name $IDE_CONTROLLER --add ide
VBoxManage storageattach "$VM_NAME" --storagectl $IDE_CONTROLLER --port 0 --device 0 --type dvddrive --medium "$ARCH_ISO_PATH"
VBoxManage storageattach "$VM_NAME" --storagectl $IDE_CONTROLLER --port 0 --device 1 --type dvddrive --medium "$VBOXADD_ISO_PATH"

VBoxManage modifyvm "$VM_NAME" --boot1 dvd --boot2 disk
VBoxManage modifyvm "$VM_NAME" --memory $RAM --vram $VRAM 

# host-only network in order to SSH.
VBoxManage modifyvm "$VM_NAME" --nic2 hostonly

HONLY_IP="192.168.42.1"
VM_IP="192.168.42.100"
# verifies if hostonly interface with the provided ip already exists
HONLY_NET=$(VBoxManage list hostonlyifs | grep $HONLY_IP -B 3 | grep Name | awk -F: '{print $2}' | xargs)
if [ -z "${HONLY_NET}" ]; then
	# case the interface doesn't exist, create a new one.
	VBoxManage hostonlyif create
	HONLY_NET=$(VBoxManage list hostonlyifs | grep $HONLY_IP -B 3 | grep Name | awk -F: '{print $2}' | xargs)
fi

VBoxManage hostonlyif ipconfig "${HONLY_NET}" --ip "${HONLY_IP}" --netmask 255.255.255.0
echo "Using host-only network: ${HONLY_NET}"
echo "Host-only network IP: ${HONLY_IP}"
VBoxManage modifyvm "$VM_NAME" --nic2 hostonly
VBoxManage modifyvm "$VM_NAME" --hostonlyadapter2 "$HONLY_NET"
VBoxManage startvm "$VM_NAME"

function count_down {
	secs=$1
	reason=$2
	while [ $secs -gt 0 ]; do
		echo -ne "Waiting... $secs: ${reason}\033[0K\r"
		sleep 1
		: $((secs--))
	done
	echo ""
}

count_down 5 "Skipping VBox start logo."
echo "Sending 'ENTER' key to "$VM_NAME"."
# 1c: pressing ENTER key; 9c: releasing ENTER key.
VBoxManage controlvm "$VM_NAME" keyboardputscancode 1c 9c

# Waiting VM to start
count_down 50 "Waiting for VM to start."

# Send keyboard keys to VM.
function send_keys_to_vm() {
	for c in $(python $DIR/echo_scancode.py "$1"); do
		VBoxManage controlvm ""$VM_NAME"" keyboardputscancode $c
		sleep 0.01
	done
}


rm -rf ~/.ssh
echo "Making VM setup SSH..."
github_raw="raw.githubusercontent.com/brunodea/my-machine/master"
SSH_SCRIPT='setup-arch-ssh.sh'
ROOT_ARCHISO_PWD='root'
# '!' is interpreted as ENTER by the echo_scancode.py script.
send_keys_to_vm "wget ${github_raw}/$SSH_SCRIPT && chmod +x $SSH_SCRIPT && ./$SSH_SCRIPT $VM_IP $ROOT_ARCHISO_PWD!"

count_down 10 "Waiting for VM to start the SSH service."
# create keys without prompting for passphrases.
if [ ! -f id_rsa ]; then
	ssh-keygen -f id_rsa -t rsa -N '' -b 2048
fi

# ssh operations without asking to confirm the host identity key.
root_addr="root@$VM_IP"
alias ssh-copy-id="ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i id_rsa.pub $root_addr"
alias ssh="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i id_rsa.pub $root_addr"
alias sftp="sftp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i id_rsa.pub $root_addr"
ssh-copy-id
sftp <<!
cd /root
put setup-arch-step1.sh
put setup-arch-step2.sh
put setup-arch-step3.sh
!
ssh <<!
cd /root
chmod +x setup-arch-step*
./setup-arch-step2.sh
!

#TODO: make this script wait on some box property that is going to be set after the VBox Guest Additions is installed in the VM.

#FIRST_SNAPSHOT_NAME="my-machine-setup"
# Snapshot after the setup is done.
#VBoxManage snapshot "$VM_NAME" take $FIRST_SNAPSHOT_NAME

# To get back to a snapshot
#VBoxManage snapshot "$VM_NAME" restore $FIRST_SNAPSHOT_NAME

