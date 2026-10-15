#!/bin/bash

IP="$1"
GW="$2"
NAME="$3"

if [ -z "$IP" ] || [ -z "$GW" ] || [ -z "$NAME" ]; then
    echo "Pemakaian: bash $0 <IP> <GATEWAY> <NAMA_HOST>"
    exit 1
fi

if ! grep -q "### SOAL1-HOST ###" /root/.bashrc; then
cat >> /root/.bashrc <<EOF
### SOAL1-HOST ###
hostname $NAME
ip addr add $IP/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route replace default via $GW
echo "nameserver 192.168.122.1" > /etc/resolv.conf
### END SOAL1-HOST ###
EOF
fi

source /root/.bashrc
echo "[$NAME] Soal 1 selesai ($IP via $GW)."