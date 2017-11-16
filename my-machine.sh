#!/bin/bash

ARCH_ISO_PATH=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

print_usage() {
	echo ""
	echo "USAGE: VBOX=<path_to_vbox_bin> PYTHON=<path_to_python> ROOT_PWD=<root_pwd> USER=<username> USER_PWD=<user_pwd> ./my-machine <arch_iso>"
	echo "Optional env vars: VM_NAME, HOSTNAME"
}

function verify_var_set() {
	if [ -z "$1" ]; then
		echo "Variable $2 was not set."
		print_usage
		exit 1
	else
		echo "$2=$1"
	fi
}

verify_var_set "$VBOX" "VBOX"
verify_var_set "$PYTHON" "PYTHON"
verify_var_set "$ROOT_PWD" "ROOT_PWD"
verify_var_set "$USER" "USER"
verify_var_set "$USER_PWD" "USER_PWD"
verify_var_set "$ARCH_ISO_PATH" "ARCH_ISO_PATH"


function exit_if_file_doesnt_exist() {
	file=$1
	if [ ! -f "$file" ]; then
		echo "File $file not found. Exiting."
		print_usage
		exit 1
	fi
}

exit_if_file_doesnt_exist "$ARCH_ISO_PATH"


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

if [ -z "$VM_NAME" ]; then
	VM_NAME='MyArch-64bits'
fi

DISK_NAME="${VM_NAME}.vid"

exit_if_exists "$VM_NAME" 'vms'
exit_if_exists "$DISK_NAME" 'hdds'

# Add VBox folder with bin files to path.
PATH="$PATH:$VBOX:$PYTHON"

DISK_SIZE=32768 # 32GB
OS_TYPE='ArchLinux_64'
RAM=4096 # 4GB
VRAM=128 

# Create dynamic disk
VBoxManage createvm --name "$VM_NAME" --ostype $OS_TYPE --register
VBoxManage createhd --filename "$DISK_NAME" --size $DISK_SIZE 

# SATA controller with the dynamic disk attached
SATA_CONTROLLER="SATA_Controller"
VBoxManage storagectl "$VM_NAME" --name $SATA_CONTROLLER --add sata --controller IntelAHCI
VBoxManage storageattach "$VM_NAME" --storagectl $SATA_CONTROLLER --port 0 --device 0 --type hdd --medium "$DISK_NAME"

# IDE controller to attach the Arch ISO and VBox Additions ISO.
IDE_CONTROLLER="IDE_Controller"
VBoxManage storagectl "$VM_NAME" --name $IDE_CONTROLLER --add ide
VBoxManage storageattach "$VM_NAME" --storagectl $IDE_CONTROLLER --port 0 --device 0 --type dvddrive --medium "$ARCH_ISO_PATH"

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

count_down 5 "Waiting for VM to start the SSH service."
# create keys without prompting for passphrases.
if [ ! -f id_rsa ]; then
	ssh-keygen -f id_rsa -t rsa -N '' -b 2048
fi

# Make a beep so the user knows he has to write the password for SSH,
# which is ROOT_ARCHISO_PWD.
echo -en "\a"
# ssh operations without asking to confirm the host identity key.
root_addr="root@$VM_IP"
ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i id_rsa $root_addr
sftp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i id_rsa $root_addr <<!
cd /root
put $DIR/setup-arch-step1.sh
put $DIR/setup-arch-step2.sh
put $DIR/setup-arch-step3.sh
put $DIR/setup-arch-step4.sh
!
# remove \r line endings in the scripts so zsh can execute them.
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i id_rsa $root_addr <<!
cd /root
sed -i -e 's/\r$//' setup-arch-step*
chmod +x setup-arch-step*
./setup-arch-step1.sh $ROOT_PWD $USER "$USER_PWD" "$HOSTNAME"
!
VBoxManage controlvm "$VM_NAME" acpipowerbutton
count_down 10 "Waiting VM to shutdown"
# Remove ARCHISO from the VM so it boots from the HDD.
VBoxManage storageattach "$VM_NAME" --storagectl $IDE_CONTROLLER --port 0 --device 0 --type dvddrive --medium none

# create snapshot before running STEP 3.
# this is useful in case we want to change STEP 3 without having to recreate everything from scratch.
FIRST_SNAPSHOT_NAME="crude-machine"
VBoxManage snapshot "$VM_NAME" take $FIRST_SNAPSHOT_NAME

VBoxManage startvm "$VM_NAME"
count_down 60 "Waiting for VM to start"

# login to VM and make it run STEP 3.
echo "Sending keys so the VM starts STEP 3..."
send_keys_to_vm "root!"
sleep 5
send_keys_to_vm "$ROOT_PWD!"
sleep 5
send_keys_to_vm "./setup-arch-step3.sh $USER \"$USER_PWD\" 2>&1 | tee /root/step3.out!"

echo "Waiting STEP_4_START property to be True..."
VBoxManage guestproperty wait "$VM_NAME" "STEP_4_START"
count_down 60 "Waiting for VM to start"

# login to VM and make it run STEP 4.
echo "Sending keys so the VM starts STEP 4..."
send_keys_to_vm "$USER!"
sleep 5
send_keys_to_vm "$USER_PWD!"
sleep 5
send_keys_to_vm "./setup-arch-step4.sh $USER 2>&1 | tee step4.out!"
VBoxManage guestproperty set "$VM_NAME" "STEP_4_START" "False"

# TODO: find a way to generate GPG keys automatically only from the guest.
echo "Waiting GPG_CONFIG_START property to be True..."
VBoxManage guestproperty wait "$VM_NAME" "GPG_CONFIG_START"
echo "Configuring GPG..."
# wait for `$gpg --full-gen-key` to start.
# then answer GPG's questions.
sleep 3
# RSA
send_keys_to_vm "!"
sleep 1
# RSA2048
send_keys_to_vm "!"
sleep 1
# Expire in 10 years
send_keys_to_vm "10y!"
sleep 1
# Is this correct?
send_keys_to_vm "y!"
sleep 1
# Real name
send_keys_to_vm "$USER!"
sleep 1
# Email
send_keys_to_vm "!"
sleep 1
# Comment
send_keys_to_vm "!"
sleep 1
# Is this okay?
send_keys_to_vm "O!"
sleep 10
# pinentry password
send_keys_to_vm "$USER_PWD!"
sleep 10
# pinentry repeat password
send_keys_to_vm "$USER_PWD!"
VBoxManage guestproperty set "$VM_NAME" "GPG_CONFIG_START" "False"

echo "Waiting ENABLE_LXDM to become True"
VBoxManage guestproperty wait "$VM_NAME" "ENABLE_LXDM"

sleep 2
send_keys_to_vm "$USER_PWD!"
VBoxManage guestproperty set "$VM_NAME" "ENABLE_LXDM" "False"

SECOND_SNAPSHOT_NAME="initial-machine"
VBoxManage snapshot "$VM_NAME" take $SECOND_SNAPSHOT_NAME
VBoxManage guestproperty set "$VM_NAME" "FINISH_SETUP" "True"

echo "My-Machine configured with success!"
