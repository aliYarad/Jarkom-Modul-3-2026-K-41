#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
which dhcpd >/dev/null 2>&1 || (apt-get update -y && apt-get install -y isc-dhcp-server)

cat > /etc/default/isc-dhcp-server <<'EOF'
INTERFACESv4="eth0"
INTERFACESv6=""
EOF

#    - Network 4: subnet lokal TANPA pool (agar tidak muncul "No subnet declaration")
#    - Network 2 & 3: scope untuk client yang datang lewat relay
cat > /etc/dhcp/dhcpd.conf <<'EOF'
authoritative;
default-lease-time 600;
max-lease-time 7200;

# Network 4 - Data Center (subnet lokal, tanpa pool dinamis)
subnet 10.84.4.0 netmask 255.255.255.0 {
}

# Network 2 - Divisi A
subnet 10.84.2.0 netmask 255.255.255.0 {
    range 10.84.2.10 10.84.2.35;
    option routers 10.84.2.1;
    option broadcast-address 10.84.2.255;
}

# Network 3 - Divisi B
subnet 10.84.3.0 netmask 255.255.255.0 {
    range 10.84.3.10 10.84.3.89;
    option routers 10.84.3.1;
    option broadcast-address 10.84.3.255;
}
EOF

mkdir -p /var/lib/dhcp
touch /var/lib/dhcp/dhcpd.leases

dhcpd -t -cf /etc/dhcp/dhcpd.conf && echo "[tengen] Konfigurasi valid."
service isc-dhcp-server restart
echo "[tengen] Soal 2 selesai."