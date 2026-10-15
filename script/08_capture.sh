#!/bin/bash

OUT=/root/soal08_capture.txt
PCAP=/root/soal08.pcap
rm -f "$OUT" "$PCAP"
command -v dhcpd >/dev/null || { echo "!!! dhcpd belum terpasang. Pasang isc-dhcp-server dulu."; exit 1; }
pgrep -x dhcpd >/dev/null || { service isc-dhcp-server restart; sleep 2; }
pgrep -x dhcpd >/dev/null || { echo "!!! dhcpd tidak jalan. Cek: dhcpd -t -cf /etc/dhcp/dhcpd.conf"; exit 1; }
echo "dhcpd PID: $(pgrep -x dhcpd | tr '\n' ' ')"
tcpdump -l -ni eth0 -vvv 'udp and (port 67 or port 68)' > "$OUT" 2>/dev/null &
P1=$!
tcpdump -ni eth0 -w "$PCAP" 'udp and (port 67 or port 68)' 2>/dev/null &
P2=$!
sleep 1
echo ">>> SIAP. Sekarang jalankan 'sh /root/08_client.sh' di itadori."
echo ">>> Setelah muncul 'lease of ... obtained', tekan ENTER di sini."
read -r _
sleep 1
kill $P1 $P2 2>/dev/null; wait $P1 $P2 2>/dev/null
cat "$OUT"
echo
echo "=================== RINGKASAN SOAL 8 ==================="
for t in Discover Offer Request ACK Release; do
  printf "%-9s : %s paket\n" "$t" "$(grep -c "DHCP-Message (53), length 1: $t" "$OUT")"
done
SID=$(grep -o 'Server-ID (54), length 4: [0-9.]*' "$OUT" | awk '{print $NF}' | sort -u | tr '\n' ' ')
YIP=$(grep -o 'Your-IP [0-9.]*' "$OUT" | awk '{print $2}' | sort -u | tr '\n' ' ')
LT=$(grep -o 'Lease-Time (51), length 4: [0-9]*' "$OUT" | awk '{print $NF}' | sort -u | tr '\n' ' ')
GIP=$(grep -o 'Gateway-IP [0-9.]*' "$OUT" | grep -v '0.0.0.0' | awk '{print $2}' | sort -u | tr '\n' ' ')
echo "--- Server-ID (alamat server) : $SID"
echo "--- Your-IP (alamat diberikan): $YIP"
echo "--- Lease-Time (detik)        : $LT"
echo "--- giaddr (Gateway-IP)       : $GIP"
Y1=$(echo $YIP | awk '{print $1}'); G1=$(echo $GIP | awk '{print $1}')
if [ -n "$Y1" ] && [ -n "$G1" ] && [ "${Y1%.*}" = "${G1%.*}" ]; then
  echo ">>> giaddr $G1 satu subnet dengan IP client $Y1 (sesuai interface jichi)."
else
  echo ">>> giaddr TIDAK cocok / kosong. Cek relay di jichi."
fi
if [ "$(grep -c 'length 1: Discover' "$OUT")" -ge 1 ] && [ "$(grep -c 'length 1: Offer' "$OUT")" -ge 1 ] && \
   [ "$(grep -c 'length 1: Request' "$OUT")" -ge 1 ] && [ "$(grep -c 'length 1: ACK' "$OUT")" -ge 1 ]; then
  echo ">>> DORA LENGKAP. Aman di-screenshot."
else
  echo ">>> DORA BELUM LENGKAP. Ulangi: jalankan lagi script ini lalu 08_client.sh."
fi
echo "File lengkap: $OUT  |  pcap: $PCAP"