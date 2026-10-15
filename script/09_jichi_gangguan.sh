#!/bin/bash

case "$1" in
  stop)
    service isc-dhcp-relay stop
    sleep 1
    killall dhcrelay 2>/dev/null
    echo "[jichi] Relay dihentikan. Status proses:"
    ps aux | grep [d]hcrelay || echo "(tidak ada proses dhcrelay -> relay MATI)"
    ;;
  start)
    if [ ! -f /etc/default/isc-dhcp-relay ]; then
        echo "[jichi] Paket relay belum ada, menjalankan 03_jichi_relay.sh ..."
        bash /root/03_jichi_relay.sh
    else
        service isc-dhcp-relay start
    fi
    sleep 1
    echo "[jichi] Relay dipulihkan. Status proses:"
    ps aux | grep [d]hcrelay
    ;;
  *)
    echo "Pemakaian: bash $0 stop|start"
    exit 1
    ;;
esac