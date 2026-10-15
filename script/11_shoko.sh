#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "nameserver 192.168.122.1" > /etc/resolv.conf
which named >/dev/null 2>&1 || (apt-get update -y && apt-get install -y bind9 bind9utils dnsutils)

cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    allow-query { any; };
    listen-on-v6 { none; };
    dnssec-validation no;
};
EOF

cat > /etc/bind/named.conf.local <<'EOF'
zone "jujutsu.K41.com" {
    type slave;
    masters { 10.84.1.2; };
    file "/var/cache/bind/jujutsu.K41.com";
};
EOF

named-checkconf && echo "[shoko] named.conf OK"
service named restart
