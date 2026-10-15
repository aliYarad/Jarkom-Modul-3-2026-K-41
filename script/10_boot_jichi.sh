#!/bin/bash

pgrep -x dhcrelay >/dev/null && exit 0
sysctl -w net.ipv4.ip_forward=1 >/dev/null
echo "nameserver 192.168.122.1" > /etc/resolv.conf
if ! command -v dhcrelay >/dev/null; then
  apt-get update || true
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confold" isc-dhcp-relay
fi
cat > /etc/default/isc-dhcp-relay <<EOF
SERVERS="10.84.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF
service isc-dhcp-relay restart
pgrep -x dhcrelay >/dev/null || dhcrelay -4 -i eth2 -i eth3 -i eth4 10.84.4.10