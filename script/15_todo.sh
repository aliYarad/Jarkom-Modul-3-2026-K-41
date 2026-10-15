cat > /root/15_geto.sh <<'SCRIPT'
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "nameserver 192.168.122.1" > /etc/resolv.conf
which nginx >/dev/null 2>&1 || (apt-get update -y && apt-get install -y nginx curl)

rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/conf.d/api_cluster.conf <<'EOF'
upstream api_cluster {
    server 10.84.4.31 weight=3;
    server 10.84.4.32 weight=1;
}

server {
    listen 80 default_server;
    server_name _;

    location /api {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
    }

    location / { return 404; }
}
EOF

nginx -t && service nginx restart
echo "[geto] load balancer siap: nanami(3) : todo(1)"
SCRIPT