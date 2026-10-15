cat > /root/13_inumaki.sh <<'SCRIPT'
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
server-id        = 2
relay_log        = /var/log/mysql/relay-bin
read_only        = 1
EOF

[ -d /var/lib/mysql/mysql ] || mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
service mariadb restart

for i in $(seq 1 30); do mariadb -e "SELECT 1" >/dev/null 2>&1 && break; sleep 1; done

mariadb <<'SQL'
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO
  MASTER_HOST='10.84.4.41',
  MASTER_USER='repl',
  MASTER_PASSWORD='ReplK41!',
  MASTER_USE_GTID=slave_pos;
START SLAVE;
SQL

sleep 3
echo "[inumaki] status replikasi"
mariadb -e "SHOW SLAVE STATUS\G" | grep -E "Master_Host|Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Last_IO_Error|Last_SQL_Error"
SCRIPT