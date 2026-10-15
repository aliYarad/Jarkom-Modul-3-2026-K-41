cat > /root/15_geto.sh <<'SCRIPT'
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "nameserver 192.168.122.1" > /etc/resolv.conf
which nginx >/dev/null 2>&1 || (apt-get update -y && apt-get install -y nginx curl)

rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/conf.d/api_cluster.conf <<'EOF'
upstream api_cluster {
    zone api_cluster 64k;
    server 10.84.4.31 weight=3;
    server 10.84.4.32 weight=1;
}

geo $trusted_proxy {
    default      0;
    10.84.1.4/32 1;
}

map "$trusted_proxy:$http_x_real_ip" $verified_ip {
    default                 $remote_addr;
    "~^1:(?<rip>.+)$"       $rip;
}

map "$trusted_proxy:$http_x_forwarded_for" $verified_xff {
    default                 $remote_addr;
    "~^1:(?<fwd>.+)$"       "$fwd, $remote_addr";
}

server {
    listen 80 default_server;
    server_name _;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $verified_ip;
    proxy_set_header X-Forwarded-For $verified_xff;

    location /api {
        proxy_pass http://api_cluster;
    }

    location / { return 404; }
}
EOF

nginx -t && service nginx restart
echo "[geto] LB siap: nanami(3):todo(1), header IP hanya dipercaya dari gojo 10.84.1.4"
SCRIPT