cat > /root/11_shoko.sh <<'SCRIPT'
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "nameserver 192.168.122.1" > /etc/resolv.conf
which named >/dev/null 2>&1 || (apt-get update -y && apt-get install -y bind9 bind9-utils bind9-dnsutils)

cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    allow-query { any; };
    recursion yes;
    allow-recursion { 10.84.0.0/16; 127.0.0.1; };
    forwarders { 192.168.122.1; };
    forward only;
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

zone "1.84.10.in-addr.arpa" {
    type slave;
    masters { 10.84.1.2; };
    file "/var/cache/bind/db.10.84.1";
};
EOF

named-checkconf && echo "[shoko] named.conf OK"
service named restart
SCRIPT