#!/bin/bash

if [ ! -d out ]; then
    mkdir out
fi

cd out

function ask_input() {
    name="$1"
    default_value="$2"
    if [ ! -z $default_value ]; then
        default_value=" (${default_value})"
    fi

    varname=""
    while [ -z $varname ]
    do
        echo -n "Type ${name}${default_value}: " >&2
        read varname
        if [ ! -z $default_value ]; then
            break
        fi
    done

    if [ -z $varname ]; then
        echo "$default_value"
    else
        echo "$varname"
    fi
}

export VBOX=`ask_input "VBOX" "/usr/local/bin/"`
export PYTHON=`ask_input "PYTHON" "/usr/bin/"`
export ROOT_PWD=`ask_input "ROOT_PWD" "password"`
export USER=`ask_input "USER" "bruno"`
export USER_PWD=`ask_input "USER_PWD" "password"`
export VM_NAME=`ask_input "VM_NAME" "MyArch"`
export HOSTNAME=`ask_input "HOSTNAME" "my-arch"`
size=`ask_input "SIZE" "extra"`

arch_current_release=$(curl -s https://www.archlinux.org/download/ | grep -i "current release" | sed 's/.*strong> //' | sed 's/<.*//')
arch_iso_name="archlinux-${arch_current_release}-x86_64.iso"

if [ ! -f $arch_iso_name ]; then
    # Download Arch ISO from swedish mirror
    wget "http://ftp.acc.umu.se/mirror/archlinux/iso/${arch_current_release}/${arch_iso_name}"
fi

../my-machine.sh "${arch_iso_name}" $size
