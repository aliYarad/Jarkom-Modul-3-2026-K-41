#!/bin/bash

pgrep -x dhcpd >/dev/null && exit 0
echo "nameserver 192.168.122.1" > /etc/resolv.conf
if ! command -v dhcpd >/dev/null; then
  apt-get update || true
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confold" isc-dhcp-server tcpdump
fi
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server
bash /root/06_tengen_fixed.sh
dhcpd -t -cf /etc/dhcp/dhcpd.conf && service isc-dhcp-server restart