# My Machine Project

This project aims to automatically create a VM on *VirtualBox* with the ideal initial setup for my needs.

All the configuration files are taken from my GitHub repo *general-cfgs*: https://github.com/brunodea/general-cfgs.

# Dependencies

* VirtualBox;
* Python;
* Arch Linux image (https://www.archlinux.org/download/).

# Running

Some environment variables *must* be set:
* VBOX: path to VirtualBox folder with its executables, such as VBoxManage;
* PYTHON: path to the Python executable, including the executable name;
* ROOT_PWD: password for the root user of the VM;
* USER: name of the default user of the VM;
* USER_PWD: password for the default user of the VM.

Run the following command:
```./my-machine.sh <path_to_arch_iso>```

If you want, you can run everything in a single command:
```VBOX=<path> \
PYTHON=<path> \
ROOT_PWD=<root_pwd> \
USER=<user> \
USER_PWD=<user_pwd> \
./my-machine.sh <path_to_arch_iso>```

*Note*: my-machine isn't currently completely automated, but it only requires manual intervention at its beginning:
	* It will be asked to type Arch's ISO root password twice: type "root".

# Structure

* my-machine.sh: Entry-point for the VM creation. It is run in the host machine and manages the VM creation and setup as well as calling the configuration steps;
