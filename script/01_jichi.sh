#!/bin/bash

sed -i '/### SOAL1-JICHI ###/,/### END SOAL1-JICHI ###/d' /root/.bashrc

cat >> /root/.bashrc <<'EOF'
### SOAL1-JICHI ###
ifup eth0 2>/dev/null
if ! ip -4 addr show dev eth0 | grep -q "inet"; then
    ip addr add 192.168.122.100/24 dev eth0 2>/dev/null
    ip link set eth0 up
    ip route replace default via 192.168.122.1
fi

ip addr add 10.84.1.1/24 dev eth1 2>/dev/null
ip addr add 10.84.2.1/24 dev eth2 2>/dev/null
ip addr add 10.84.3.1/24 dev eth3 2>/dev/null
ip addr add 10.84.4.1/24 dev eth4 2>/dev/null
for i in eth1 eth2 eth3 eth4; do ip link set $i up; done

sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "nameserver 192.168.122.1" > /etc/resolv.conf
### END SOAL1-JICHI ###
EOF

source /root/.bashrc
echo "[jichi] Soal 1 selesai."
