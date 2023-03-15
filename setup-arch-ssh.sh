#!/bin/bash

IP=$1
ROOT_PWD=$2

echo "Adding IP address ${IP}..."

ip_base="$(echo $IP | cut -d'.' -f1-3)"

echo "ip_base: ${ip_base}"

NET_INTERFACE="$(ip -o addr show | grep $ip_base | awk -F\  'NR==1{print $2}')"

if [ -z $NET_INTERFACE ]
then
    echo "Network interface not found! Using the default one..."
    NET_INTERFACE="enp0s8"
fi

echo "Network interface: ${NET_INTERFACE}"

ip addr add $IP/24 dev $NET_INTERFACE

echo -e "${ROOT_PWD}\n${ROOT_PWD}" | passwd root
sed -i 's/#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config