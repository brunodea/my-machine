# My Machine Project

This project aims to automatically create a VM on *VirtualBox* with the ideal initial setup for my needs.

All the configuration files are taken from my GitHub repo *general-cfgs*: https://github.com/brunodea/general-cfgs.

# Dependencies

* VirtualBox;
* Python;
* Arch Linux image (https://www.archlinux.org/download/).

# Running

Run the following script:

`./run.sh`

It will prompt you to set the environment variables (see below).
It also downloads the latest version of Arch ISO to `my-machine/out/`.
After that, it will run `my-machine.sh`.

Note that all files generated by the script will be located in `my-machine/out/`. This includes VirtualBox-specific files, such as the virtual hard disk, and id_rsa files.

Some environment variables *must* be set:
* `VBOX`: path to VirtualBox folder with its executables, such as VBoxManage;
* `PYTHON`: path to the Python folder with its executable;
* `ROOT_PWD`: password for the root user of the VM;
* `USER`: name of the default user of the VM;
* `USER_PWD`: password for the default user of the VM.

`<size>` refers to the amount of memory that will be used for the VM:
* `small`: 32GB HDD, 1GB RAM, 32MB VRAM;
* `medium`: 32GB HDD, 2GB RAM, 64MB VRAM;
* `large`: 48GB HDD, 4GB RAM, 128MB VRAM;
* `extra`: 48GB HDD, 6GB RAM, 128MB VRAM.



*Notes*:
* my-machine isn't currently completely automated, but it only requires manual intervention once around 5min after the script was run:
	* It will be asked to type Arch's ISO root password: type "root";
* choose passwords at least 8 chars long for `ROOT_PWD` and `USER_PWD`;
* the VM's .vdi file will be created in the directory where `my-machine.sh` was run from.

# Structure

* my-machine.sh: Entry-point for the VM creation. It is run in the host machine and manages the VM creation and setup as well as calling the configuration steps;

# TODO
