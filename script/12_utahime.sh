cat > /root/11_utahime.sh <<'SCRIPT'
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "nameserver 192.168.122.1" > /etc/resolv.conf
which named >/dev/null 2>&1 || (apt-get update -y && apt-get install -y bind9 bind9-utils bind9-dnsutils)

mkdir -p /etc/bind/jujutsu

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
    type master;
    file "/etc/bind/jujutsu/jujutsu.K41.com";
    notify yes;
    also-notify { 10.84.1.3; };
    allow-transfer { 10.84.1.3; };
};

zone "1.84.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jujutsu/db.10.84.1";
    notify yes;
    also-notify { 10.84.1.3; };
    allow-transfer { 10.84.1.3; };
};
EOF

cat > /etc/bind/jujutsu/jujutsu.K41.com <<'EOF'
$TTL 604800
@   IN  SOA ns1.jujutsu.K41.com. root.jujutsu.K41.com. (
            2026101512  ; serial
            3600
            600
            604800
            86400 )
;
@   IN  NS  ns1.jujutsu.K41.com.
@   IN  NS  ns2.jujutsu.K41.com.
ns1 IN  A   10.84.1.2
ns2 IN  A   10.84.1.3
@   IN  A   10.84.1.4
www IN  CNAME jujutsu.K41.com.
EOF

cat > /etc/bind/jujutsu/db.10.84.1 <<'EOF'
$TTL 604800
@   IN  SOA ns1.jujutsu.K41.com. root.jujutsu.K41.com. (
            2026101512  ; serial
            3600
            600
            604800
            86400 )
;
@   IN  NS  ns1.jujutsu.K41.com.
@   IN  NS  ns2.jujutsu.K41.com.
2   IN  PTR ns1.jujutsu.K41.com.
3   IN  PTR ns2.jujutsu.K41.com.
4   IN  PTR jujutsu.K41.com.
EOF

named-checkconf && echo "[utahime] named.conf OK"
named-checkzone jujutsu.K41.com /etc/bind/jujutsu/jujutsu.K41.com
named-checkzone 1.84.10.in-addr.arpa /etc/bind/jujutsu/db.10.84.1
service named restart
SCRIPT