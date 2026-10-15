#!/bin/bash

MAC_ITADORI="02:42:ca:0c:2a:00"
MAC_FUSHIGURO="02:42:2c:10:8f:00"
MAC_ZENIN="02:42:4a:14:24:00"
MAC_OKKOTSU="02:42:bc:7b:16:00"

for m in "$MAC_ITADORI" "$MAC_FUSHIGURO" "$MAC_ZENIN" "$MAC_OKKOTSU"; do
    case "$m" in
        GANTI_*) echo "ERROR: MAC belum diisi ($m). Edit bagian atas script."; exit 1;;
    esac
done

cat > /etc/dhcp/dhcpd.conf <<EOF
authoritative;
default-lease-time 600;
max-lease-time 7200;

class "pool1" {
    match if substring(hardware, 1, 6) = $MAC_ITADORI
          or substring(hardware, 1, 6) = $MAC_FUSHIGURO;
}
class "pool2" {
    match if substring(hardware, 1, 6) = $MAC_ZENIN
          or substring(hardware, 1, 6) = $MAC_OKKOTSU;
}

# Network 4 - Data Center
subnet 10.84.4.0 netmask 255.255.255.0 {
}

# Network 2 - Divisi A
subnet 10.84.2.0 netmask 255.255.255.0 {
    option routers 10.84.2.1;
    option broadcast-address 10.84.2.255;

    pool {
        range 10.84.2.10 10.84.2.35;
        allow members of "pool1";
    }
    pool {
        range 10.84.2.70 10.84.2.95;
        allow members of "pool2";
    }
}

# Network 3 - Divisi B
subnet 10.84.3.0 netmask 255.255.255.0 {
    range 10.84.3.10 10.84.3.89;
    option routers 10.84.3.1;
    option broadcast-address 10.84.3.255;
}
EOF

dhcpd -t -cf /etc/dhcp/dhcpd.conf && echo "[tengen] Konfigurasi valid." || exit 1
service isc-dhcp-server restart
echo "[tengen] Soal 4 selesai."