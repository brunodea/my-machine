#!/bin/bash

function ask_input() {
    local name="$1"
    local default_value="$2"
    local par=""
    if [ ! -z $default_value ]; then
        par=" (${default_value})"
    fi

    local varname=""
    while [ -z "$varname" ]
    do
        echo -n "Type ${name}${par}: " >&2
        read varname
        if [ ! -z $default_value ]; then
            break
        fi
    done

    if [ -z "$varname" ]; then
        echo "$default_value"
    else
        echo "$varname"
    fi
}

function ask_env() {
    local name="$1"
    local default_value="$2"

    if [ -z "${name}" ]
    then
        export $name=`ask_input "${name}" "${default_value}"`
    fi
}

if [ -f .env ]
then
    while read line; do
        lhs=$(echo $line | cut -d'=' -f1)
        rhs=$(echo $line | cut -d'=' -f2)
        export $lhs="$(echo $rhs | sed 's/"//g')"
    done < .env
fi

ask_env "ISO" "path/to/arch.iso"
ask_env "VBOX" "/usr/local/bin/"
ask_env "PYTHON" "/usr/bin/"
ask_env "ROOT_PWD" "password"
ask_env "USER" "bruno"
ask_env "USER_PWD" "bruno"
ask_env "VM_NAME" "MyArch2023"
ask_env "HOSTNAME" "myarch"
ask_env "LONG_COUNTDOWN_WAIT" 35
ask_env "SIZE" "extra-large"

#arch_current_release=$(curl -s https://www.archlinux.org/download/ | grep -i "current release" | sed 's/.*strong> //' | sed 's/<.*//')
#arch_iso_name="archlinux-${arch_current_release}-x86_64.iso"
#if [ ! -f $arch_iso_name ]; then
#    # Download Arch ISO from swedish mirror
#    wget "http://ftp.acc.umu.se/mirror/archlinux/iso/${arch_current_release}/${arch_iso_name}"
#fi

./my-machine.sh "${ISO}" "${SIZE}"