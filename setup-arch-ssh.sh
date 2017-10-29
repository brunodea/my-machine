#!/bin/bash

IP=$1
ROOT_PSW=$2

NET_INTERFACE="$(ifconfig -s | awk 'NR==3{print $1}')"
ifconfig "$NET_INTERFACE" "$IP" netmask 255.255.255.0 up
spawn passwd
expect "New password:"
send "$ROOT_PSW\n"
expect "Retype new password:"
send "$ROOT_PSW\n"

sed -i 's/#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
systemctl start sshd.service
