cat > /root/14_maki.sh <<'SCRIPT'
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "nameserver 192.168.122.1" > /etc/resolv.conf

HOST=$(hostname)
case "$HOST" in
  maki|panda)             ROLE=web; PROXY_IP=10.84.1.4 ;;
  nanami|todo|kirara)     ROLE=api; PROXY_IP=10.84.4.2 ;;
  *) echo "hostname $HOST tidak dikenal"; exit 1 ;;
esac

which nginx >/dev/null 2>&1 && ls /etc/php/*/fpm >/dev/null 2>&1 || \
  (apt-get update -y && apt-get install -y nginx php-fpm php-mysql curl)

PHPV=$(ls /etc/php/ | sort -V | tail -1)
SOCK=/run/php/php${PHPV}-fpm.sock

mkdir -p /var/www/web /var/www/api

cat > /var/www/web/index.php <<'PHP'
<?php
$h = gethostname();
echo "<h1>Frontend Jujutsu High</h1>";
echo "<p>Halaman ini dilayani oleh worker: <b>$h</b></p>";
PHP

cat > /var/www/api/index.php <<'PHP'
<?php
header('Content-Type: application/json');
mysqli_report(MYSQLI_REPORT_OFF);
$host   = gethostname();
$client = $_SERVER['REMOTE_ADDR'];
$path   = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$code   = 200;
$saved  = false;
$error  = null;
$db = @new mysqli('10.84.4.41', 'shibuya', 'ShibuyaK41!', 'db_shibuya_K41');
if ($db->connect_errno) {
    $error = $db->connect_error;
} else {
    $st = $db->prepare('INSERT INTO request_logs (client_ip, request_path, status_code, handled_by) VALUES (?,?,?,?)');
    $st->bind_param('ssis', $client, $path, $code, $host);
    $saved = $st->execute();
    if (!$saved) { $error = $st->error; }
    $db->close();
}
echo json_encode([
    'service'   => 'jujutsu-api',
    'handled_by'=> $host,
    'client_ip' => $client,
    'path'      => $path,
    'db_saved'  => $saved,
    'db_error'  => $error
]);
PHP

rm -f /etc/nginx/sites-enabled/default

if [ "$ROLE" = "web" ]; then
cat > /etc/nginx/sites-available/jujutsu <<EOF
server {
    listen 80 default_server;
    server_name jujutsu.K41.com www.jujutsu.K41.com;
    root /var/www/web;
    index index.php;

    allow 127.0.0.1;
    allow ${PROXY_IP};
    deny all;

    location / { try_files \$uri \$uri/ =404; }
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${SOCK};
    }
}
EOF
else
cat > /etc/nginx/sites-available/jujutsu <<EOF
server {
    listen 80 default_server;
    server_name jujutsu.K41.com www.jujutsu.K41.com;

    allow 127.0.0.1;
    allow ${PROXY_IP};
    deny all;

    location ^~ /api {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/api/index.php;
        fastcgi_pass unix:${SOCK};
    }
    location / { return 404; }
}
EOF
fi

ln -sf /etc/nginx/sites-available/jujutsu /etc/nginx/sites-enabled/jujutsu

service php${PHPV}-fpm restart
nginx -t && service nginx restart
echo "[$HOST] role=$ROLE proxy_diizinkan=$PROXY_IP php=$PHPV"
SCRIPT