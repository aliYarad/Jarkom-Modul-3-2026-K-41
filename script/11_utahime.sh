#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "nameserver 192.168.122.1" > /etc/resolv.conf
which named >/dev/null 2>&1 || (apt-get update -y && apt-get install -y bind9 bind9utils dnsutils)

mkdir -p /etc/bind/jujutsu

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
    type master;
    file "/etc/bind/jujutsu/jujutsu.K41.com";
    notify yes;
    also-notify { 10.84.1.3; };
    allow-transfer { 10.84.1.3; };
};
EOF

cat > /etc/bind/jujutsu/jujutsu.K41.com <<'EOF'
$TTL 604800
@   IN  SOA ns1.jujutsu.K41.com. root.jujutsu.K41.com. (
            2026101511  ; serial
            3600        ; refresh
            600         ; retry
            604800      ; expire
            86400 )     ; negative cache TTL
;
@   IN  NS  ns1.jujutsu.K41.com.
@   IN  NS  ns2.jujutsu.K41.com.
ns1 IN  A   10.84.1.2
ns2 IN  A   10.84.1.3
EOF

named-checkconf && echo "[utahime] named.conf OK"
named-checkzone jujutsu.K41.com /etc/bind/jujutsu/jujutsu.K41.com
service named restart
