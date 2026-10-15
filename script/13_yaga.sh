#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "nameserver 192.168.122.1" > /etc/resolv.conf
which mariadbd >/dev/null 2>&1 || (apt-get update -y && apt-get install -y mariadb-server mariadb-client)

mkdir -p /etc/mysql/mariadb.conf.d /var/log/mysql /run/mysqld
chown mysql:mysql /var/log/mysql /run/mysqld

cat > /etc/mysql/mariadb.conf.d/99-shibuya.cnf <<'EOF'
[mysqld]
bind-address     = 0.0.0.0
skip-name-resolve
server-id        = 1
log_bin          = /var/log/mysql/mariadb-bin
binlog_format    = ROW
EOF

[ -d /var/lib/mysql/mysql ] || mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
service mariadb restart

for i in $(seq 1 30); do mariadb -e "SELECT 1" >/dev/null 2>&1 && break; sleep 1; done

mariadb <<'SQL'
CREATE DATABASE IF NOT EXISTS db_shibuya_K41;
CREATE TABLE IF NOT EXISTS db_shibuya_K41.request_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  request_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  client_ip VARCHAR(45),
  request_path VARCHAR(255),
  status_code INT,
  handled_by VARCHAR(50)
);
CREATE USER IF NOT EXISTS 'repl'@'10.84.4.%' IDENTIFIED BY 'ReplK41!';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'10.84.4.%';
CREATE USER IF NOT EXISTS 'shibuya'@'10.84.4.%' IDENTIFIED BY 'ShibuyaK41!';
GRANT ALL PRIVILEGES ON db_shibuya_K41.* TO 'shibuya'@'10.84.4.%';
FLUSH PRIVILEGES;
SQL

echo "[yaga] master siap"
mariadb -e "SHOW MASTER STATUS;"
