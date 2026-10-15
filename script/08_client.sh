#!/bin/sh

ip link set eth0 up
echo "[1] Rilis lease lama (hanya 1 proses, supaya Release tidak dobel)"
P=$(pidof udhcpc | awk '{print $1}')
[ -n "$P" ] && { kill -USR2 "$P"; sleep 2; }
killall -9 udhcpc 2>/dev/null
sleep 1
echo "    proses udhcpc tersisa: $(pidof udhcpc | wc -w)  (harus 0)"
echo "[2] Minta lease baru -> ini yang ditangkap sebagai DORA"
udhcpc -i eth0
sleep 2
echo "[3] Hasil"
ip -br a show eth0
ip r