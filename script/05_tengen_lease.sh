#!/bin/bash

GROUP="K41"
MAC_ITADORI="02:42:ca:0c:2a:00"
MAC_FUSHIGURO="02:42:2c:10:8f:00"
MAC_ZENIN="02:42:4a:14:24:00"
MAC_OKKOTSU="02:42:bc:7b:16:00"
MAC_INO="02:42:7d:1f:d9:00"
MAC_KUSAKABE="02:42:65:95:ef:00"
MAC_MIWA="02:42:90:34:fc:00"

for m in "$GROUP" "$MAC_KUSAKABE" "$MAC_MIWA"; do
    case "$m" in
        GANTI_*) echo "ERROR: nilai belum diisi ($m). Edit bagian atas script."; exit 1;;
    esac
done

cat > /etc/dhcp/dhcpd.conf <<EOF
authoritative;
default-lease-time 600;
max-lease-time 7200;

# DHCP options untuk semua client
option domain-name-servers 10.84.1.2, 10.84.1.3;
option domain-search "$GROUP.com";

# ---------- Class Network 2 (Divisi A) ----------
class "pool1" {
    match if substring(hardware, 1, 6) = $MAC_ITADORI
          or substring(hardware, 1, 6) = $MAC_FUSHIGURO;
}
class "pool2" {
    match if substring(hardware, 1, 6) = $MAC_ZENIN
          or substring(hardware, 1, 6) = $MAC_OKKOTSU;
}

# ---------- Class Network 3 (Divisi B) ----------
# short lease 30 menit (1800 detik): ino, kusakabe
class "short" {
    match if substring(hardware, 1, 6) = $MAC_INO
          or substring(hardware, 1, 6) = $MAC_KUSAKABE;
    default-lease-time 1800;
    max-lease-time 1800;
}
# long lease 12 jam (43200 detik): miwa
class "long" {
    match if substring(hardware, 1, 6) = $MAC_MIWA;
    default-lease-time 43200;
    max-lease-time 43200;
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
    option routers 10.84.3.1;
    option broadcast-address 10.84.3.255;

    pool {
        range 10.84.3.10 10.84.3.89;
        allow members of "short";
    }
    pool {
        range 10.84.3.100 10.84.3.199;
        allow members of "long";
    }
}
EOF

dhcpd -t -cf /etc/dhcp/dhcpd.conf && echo "[tengen] Konfigurasi valid." || exit 1
service isc-dhcp-server restart
echo "[tengen] Soal 5 selesai."