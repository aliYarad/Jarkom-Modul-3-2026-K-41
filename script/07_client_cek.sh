#!/bin/sh

echo "=== HOSTNAME ==="
hostname

echo "=== MINTA LEASE ==="
ip link set eth0 up
udhcpc -i eth0

echo "=== IP ADDRESS ==="
ip -br a

echo "=== ROUTING ==="
ip r

echo "=== DNS (resolv.conf) ==="
cat /etc/resolv.conf

echo "=== OPSI DHCP YANG DITERIMA (termasuk domain-search / option 119) ==="
printf '#!/bin/sh\nenv | grep -E "^(search|domain|dns|router|subnet|broadcast|lease)"\n' > /tmp/show.sh
chmod +x /tmp/show.sh
udhcpc -i eth0 -n -q -O 119 -s /tmp/show.sh