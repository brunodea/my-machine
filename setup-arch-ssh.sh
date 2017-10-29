#!/bin/bash

IP=$1
ROOT_PWD=$2

NET_INTERFACE="$(ifconfig -s | awk 'NR==3{print $1}')"
ifconfig "$NET_INTERFACE" "$IP" netmask 255.255.255.0 up
echo "root:${ROOT_PWD}" | chgpasswd
sed -i 's/#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
systemctl start sshd.service
