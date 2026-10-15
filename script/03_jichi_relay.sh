#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
which dhcrelay >/dev/null 2>&1 || (apt-get update -y && apt-get install -y isc-dhcp-relay)

cat > /etc/default/isc-dhcp-relay <<'EOF'
SERVERS="10.84.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF

service isc-dhcp-relay restart
echo "[jichi] Soal 3 (relay) selesai."