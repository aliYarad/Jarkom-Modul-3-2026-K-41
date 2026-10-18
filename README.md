# Jarkom-Modul-3-2026-K-41

|         Nama         |     NRP     |
|----------------------|-------------|
|Aliya Rahmadina       | 5027251056  |
|Rayhan Fadhilah Allayn| 5027251126  |

## Soal 1
Ketika Curtain menutup Shibuya, jalur komunikasi antar zona Jujutsu High terputus. Pulihkan konektivitas dasar dengan mengonfigurasi jichi: eth0 memperoleh WAN dari NAT, sedangkan eth1–eth4 menjadi gateway Network 1–4 sesuai tabel pemetaan. Aktifkan IPv4 forwarding dan source NAT, lalu tetapkan IP statis host infrastruktur sesuai tabel spesifikasi. Buktikan konektivitas setiap host ke gateway dan akses eksternal dari host yang relevan.

### Ringkasan
*jichi dikonfigurasi sebagai router utama: `eth0` mendapat WAN dari NAT, `eth1`–`eth4` menjadi gateway Network 1–4 (`10.84.1.1`–`10.84.4.1`, /24), IPv4 forwarding dan source NAT (MASQUERADE) aktif. Seluruh host infrastruktur diberi IP statis, dibuktikan dapat ping ke gateway, dan akses eksternal dibuktikan dari utahime.*

### Langkah Pengerjaan
1. Mencocokkan interface jichi dengan topologi GNS3: `eth0` → NAT1, `eth1` → Switch1 (Network 1), `eth2` → Switch2 (Network 2), `eth3` → Switch4 (Network 3), `eth4` → Switch6 (Network 4).
2. Membuat script `/root/01_jichi.sh` pada jichi. Script menulis blok konfigurasi ke `/root/.bashrc` yang berisi: `eth0` meminta IP dari NAT (dengan cadangan IP statis bila DHCP NAT gagal), IP gateway `eth1`–`eth4`, IPv4 forwarding, rule MASQUERADE pada `eth0`, dan resolver awal `192.168.122.1`.
3. Membuat script `/root/01_host.sh` pada setiap host infrastruktur (image debinet). Script menerima tiga argumen: IP, gateway, dan nama host.
4. Menjalankan script pada jichi, lalu pada tiap host dengan IP dan gateway sesuai tabel.
5. Memverifikasi IP, route, dan konektivitas dengan `ip -br a`, `ip r`, dan `ping`.

### Command
**jichi** — `/root/01_jichi.sh`
```
#!/bin/bash
sed -i '/### SOAL1-JICHI ###/,/### END SOAL1-JICHI ###/d' /root/.bashrc
 
cat >> /root/.bashrc <<'EOF'
### SOAL1-JICHI ###
ifup eth0 2>/dev/null
if ! ip -4 addr show dev eth0 | grep -q "inet"; then
    ip addr add 192.168.122.100/24 dev eth0 2>/dev/null
    ip link set eth0 up
    ip route replace default via 192.168.122.1
fi
 
ip addr add 10.84.1.1/24 dev eth1 2>/dev/null
ip addr add 10.84.2.1/24 dev eth2 2>/dev/null
ip addr add 10.84.3.1/24 dev eth3 2>/dev/null
ip addr add 10.84.4.1/24 dev eth4 2>/dev/null
for i in eth1 eth2 eth3 eth4; do ip link set $i up; done
 
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
 
echo "nameserver 192.168.122.1" > /etc/resolv.conf
### END SOAL1-JICHI ###
EOF
 
source /root/.bashrc
echo "[jichi] Soal 1 selesai."
```
 
- `ifup eth0`: `eth0` meminta IP dari DHCP milik NAT (hasilnya `192.168.122.x`).
- `ip addr add 10.84.N.1/24 dev ethN`: memasang alamat gateway tiap network.
- `sysctl -w net.ipv4.ip_forward=1`: kernel meneruskan paket antar-interface.
- `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE`: source NAT agar paket dari jaringan internal keluar memakai IP `eth0`. Opsi `-C` memeriksa dulu supaya rule tidak ganda.
**Host infrastruktur** — `/root/01_host.sh <IP> <GATEWAY> <NAMA_HOST>`
 
```
#!/bin/bash
IP="$1"
GW="$2"
NAME="$3"
 
if ! grep -q "### SOAL1-HOST ###" /root/.bashrc; then
cat >> /root/.bashrc <<EOF
### SOAL1-HOST ###
hostname $NAME
ip addr add $IP/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route replace default via $GW
echo "nameserver 192.168.122.1" > /etc/resolv.conf
### END SOAL1-HOST ###
EOF
fi
 
source /root/.bashrc
echo "[$NAME] Soal 1 selesai ($IP via $GW)."
```
 
Perintah yang dijalankan di tiap node:
 
```
bash /root/01_host.sh 10.84.1.2  10.84.1.1 utahime
bash /root/01_host.sh 10.84.1.3  10.84.1.1 shoko
bash /root/01_host.sh 10.84.1.4  10.84.1.1 gojo
bash /root/01_host.sh 10.84.4.10 10.84.4.1 tengen
bash /root/01_host.sh 10.84.4.2  10.84.4.1 geto
bash /root/01_host.sh 10.84.4.21 10.84.4.1 maki
bash /root/01_host.sh 10.84.4.22 10.84.4.1 panda
bash /root/01_host.sh 10.84.4.31 10.84.4.1 nanami
bash /root/01_host.sh 10.84.4.32 10.84.4.1 todo
bash /root/01_host.sh 10.84.4.33 10.84.4.1 kirara
bash /root/01_host.sh 10.84.4.41 10.84.4.1 yaga
bash /root/01_host.sh 10.84.4.42 10.84.4.1 inumaki
```
 
**Verifikasi**
 
```
# jichi
ip -br a
ip r
cat /proc/sys/net/ipv4/ip_forward
iptables -t nat -L POSTROUTING -n -v
ping -c 3 192.168.122.1
ping -c 3 8.8.8.8
ping -c 3 google.com
 
# setiap host
hostname
ip -br a
ip r
ping -c 3 <gateway>
 
# host yang relevan (utahime): akses eksternal
ping -c 3 8.8.8.8
ping -c 3 google.com
```
 
Hasil: `eth1`–`eth4` pada jichi ber-IP `10.84.1.1`–`10.84.4.1` (/24), forwarding bernilai `1`, rule `MASQUERADE` aktif pada `eth0`, dan ping ke gateway NAT, `8.8.8.8`, serta `google.com` berhasil. Seluruh 12 host infrastruktur berhasil ping ke gateway masing-masing, dan utahime berhasil mengakses internet melalui NAT jichi.
 
## Soal 2
Tengen, penjaga pusat distribusi di Data Center, harus mengambil alih pengalokasian alamat bagi wilayah yang membutuhkan konfigurasi dinamis. Konfigurasikan isc-dhcp-server pada [PREFIX IP].4.10. Deklarasikan Network 4 ([PREFIX IP].4.0/24) sebagai subnet lokal tanpa pool dinamis, lalu siapkan scope DHCP untuk Network 2 ([PREFIX IP].2.0/24) dan Network 3 ([PREFIX IP].3.0/24). Validasi konfigurasi dan pastikan service aktif tanpa error “No subnet declaration”.

### Ringkasan
*Pada tengen (`10.84.4.10`) dipasang `isc-dhcp-server` dengan `eth0` sebagai interface layanan. Network 4 dideklarasikan sebagai subnet lokal tanpa `range`, sedangkan Network 2 dan Network 3 memiliki scope DHCP. Konfigurasi divalidasi dengan `dhcpd -t` dan service berjalan tanpa error.*

### Langkah Pengerjaan
1. Memasang `isc-dhcp-server` pada tengen (butuh internet melalui jichi dan resolver `192.168.122.1`).
2. Mengatur interface layanan pada `/etc/default/isc-dhcp-server` menjadi `eth0` (`10.84.4.10`).
3. Menulis `/etc/dhcp/dhcpd.conf`: subnet Network 4 **tanpa** `range`, serta scope Network 2 dan Network 3 lengkap dengan `routers` dan `broadcast-address`.
4. Memvalidasi konfigurasi dengan `dhcpd -t`, lalu menjalankan service.
5. Memeriksa status service, proses, dan port UDP 67.
Subnet Network 4 harus dideklarasikan walaupun tanpa pool, karena `dhcpd` menolak berjalan (`No subnet declaration for eth0`) bila interface yang dipakai tidak memiliki subnet yang cocok pada konfigurasi.

### Command
**tengen** — `/root/02_tengen.sh`
 
```
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
which dhcpd >/dev/null 2>&1 || (apt-get update -y && apt-get install -y isc-dhcp-server)
 
cat > /etc/default/isc-dhcp-server <<'EOF'
INTERFACESv4="eth0"
INTERFACESv6=""
EOF
 
cat > /etc/dhcp/dhcpd.conf <<'EOF'
authoritative;
default-lease-time 600;
max-lease-time 7200;
 
# Network 4 - Data Center (subnet lokal, tanpa pool dinamis)
subnet 10.84.4.0 netmask 255.255.255.0 {
}
 
# Network 2 - Divisi A
subnet 10.84.2.0 netmask 255.255.255.0 {
    range 10.84.2.10 10.84.2.35;
    option routers 10.84.2.1;
    option broadcast-address 10.84.2.255;
}
 
# Network 3 - Divisi B
subnet 10.84.3.0 netmask 255.255.255.0 {
    range 10.84.3.10 10.84.3.89;
    option routers 10.84.3.1;
    option broadcast-address 10.84.3.255;
}
EOF
 
mkdir -p /var/lib/dhcp
touch /var/lib/dhcp/dhcpd.leases
 
dhcpd -t -cf /etc/dhcp/dhcpd.conf && echo "[tengen] Konfigurasi valid."
service isc-dhcp-server restart
echo "[tengen] Soal 2 selesai."
```
 
> Rentang `range` pada Network 2 dan Network 3 di tahap ini bersifat sementara, kemudian ditulis ulang pada Soal 4 sampai Soal 6.
 
**Verifikasi**
 
```
cat /etc/default/isc-dhcp-server
cat /etc/dhcp/dhcpd.conf
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server status
ps aux | grep [d]hcpd
ss -ulnp | grep :67
```
 
Hasil: konfigurasi valid (`[tengen] Konfigurasi valid.`), `dhcpd is running`, proses `dhcpd -4 ... eth0` berjalan, dan `dhcpd` mendengarkan pada UDP `0.0.0.0:67`, tanpa error "No subnet declaration".

## Soal 3
Permintaan alamat dari Divisi A dan Divisi B tidak dapat menyeberangi subnet secara langsung. Konfigurasikan jichi sebagai DHCP Relay menuju tengen ([PREFIX IP].4.10), menggunakan eth2 untuk Network 2 dan eth3 untuk Network 3. Buktikan bahwa client dari kedua subnet berhasil memperoleh lease melalui relay.

### Ringkasan
*jichi dikonfigurasi sebagai DHCP Relay menuju tengen (`10.84.4.10`) untuk Network 2 (`eth2`) dan Network 3 (`eth3`). Interface `eth4` (jalur ke server) ikut diikat agar balasan dari tengen diterima relay. Client itadori (Network 2) dan ino (Network 3) berhasil memperoleh lease melalui relay.*
 
### Langkah Pengerjaan
1. Memasang `isc-dhcp-relay` pada jichi.
2. Mengisi `/etc/default/isc-dhcp-relay` dengan `SERVERS="10.84.4.10"` dan `INTERFACES` berisi `eth2 eth3`, lalu menjalankan service.
3. Menguji dari client Network 2 (itadori) dengan `ip link set eth0 up` dan `udhcpc -i eth0`. **Client tidak memperoleh lease** (`udhcpc failed to get a DHCP lease`).
4. Menangkap paket pada jichi dengan `tcpdump -ni any port 67 or port 68`. Hasilnya: DISCOVER client masuk di `eth2`, diteruskan ke `10.84.4.10` melalui `eth4`, dan balasan dari tengen kembali di `eth4`, tetapi **tidak diteruskan keluar ke `eth2`**. Relay hanya terikat ke `eth2` dan `eth3`, sehingga paket yang datang lewat `eth4` tidak diproses.
5. Menambahkan `eth4` pada `INTERFACES` (`eth2 eth3 eth4`), lalu me-restart relay.
6. Menguji ulang dari itadori (Network 2) dan ino (Network 3). Kedua client memperoleh lease dari server `10.84.4.10`.
7. Memeriksa pencatatan lease pada tengen.

### Command
**jichi** — `/root/03_jichi_relay.sh`
 
```
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
```
 
**Diagnosa** (jichi)
 
```
tcpdump -ni any port 67 or port 68
```
 
**Client** (itadori dan ino)
 
```
ip link set eth0 up
udhcpc -i eth0
ip -br a
ip r
```
 
**Verifikasi**
 
```
# jichi
cat /etc/default/isc-dhcp-relay
ps aux | grep [d]hcrelay
 
# tengen
tail -30 /var/lib/dhcp/dhcpd.leases
```
 
Hasil: proses `dhcrelay -q -i eth2 -i eth3 -i eth4 10.84.4.10` berjalan. itadori memperoleh `10.84.2.10` (gateway `10.84.2.1`) dan ino memperoleh `10.84.3.10` (gateway `10.84.3.1`), keduanya dari server `10.84.4.10`, dan lease tercatat pada `dhcpd.leases` di tengen.

## Soal 4
Agar tim Dev dan Support di Divisi A menerima jatah alamat yang berbeda, atur dua pool DHCP pada Network 2. Tetapkan Pool 1 ([PREFIX IP].2.10–[PREFIX IP].2.35) untuk itadori dan fushiguro, serta Pool 2 ([PREFIX IP].2.70–[PREFIX IP].2.95) untuk zenin dan okkotsu. Rentang [PREFIX IP].2.36–[PREFIX IP].2.69 tidak boleh dialokasikan. Karena seluruh client berada pada subnet yang sama, gunakan DHCP class berdasarkan MAC Address atau Client ID untuk memisahkan kedua kelompok.

### Ringkasan
*Network 2 dibagi menjadi dua pool menggunakan DHCP class berdasarkan MAC address: `pool1` (`10.84.2.10`–`10.84.2.35`) untuk itadori dan fushiguro, `pool2` (`10.84.2.70`–`10.84.2.95`) untuk zenin dan okkotsu. Rentang `10.84.2.36`–`10.84.2.69` tidak dimasukkan ke pool mana pun.*

### Langkah Pengerjaan
1. Mengambil MAC address `eth0` keempat client dengan `ip link show eth0` (dan dicocokkan dengan **Show node information** di GNS3).
2. Mendefinisikan dua class `pool1` dan `pool2` yang mencocokkan `substring(hardware, 1, 6)` dengan MAC masing-masing client.
3. Pada subnet Network 2, mengganti `range` tunggal dengan dua blok `pool`. Setiap pool memiliki `range` sendiri dan `allow members of` class yang bersesuaian.
4. Memvalidasi konfigurasi dan me-restart service di tengen.
5. Meminta lease dari keempat client dan memeriksa IP yang diperoleh.

### Command
**tengen** — `/root/04_tengen_pool.sh` (bagian konfigurasi Network 2)
 
```
class "pool1" {
    match if substring(hardware, 1, 6) = 02:42:ca:0c:2a:00
          or substring(hardware, 1, 6) = 02:42:2c:10:8f:00;
}
class "pool2" {
    match if substring(hardware, 1, 6) = 02:42:4a:14:24:00
          or substring(hardware, 1, 6) = 02:42:bc:7b:16:00;
}
 
subnet 10.84.2.0 netmask 255.255.255.0 {
    option routers 10.84.2.1;
    option broadcast-address 10.84.2.255;
 
    pool {
        range 10.84.2.10 10.84.2.35;
        allow members of "pool1";
    }
    pool {
        range 10.84.2.70 10.84.2.95;
        allow members of "pool2";
    }
}
```
 
```
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server restart
```
 
**Client** (itadori, fushiguro, zenin, okkotsu)
 
```
ip link show eth0
udhcpc -i eth0
ip -br a
```
 
**Verifikasi** (tengen)
 
```
cat /etc/dhcp/dhcpd.conf
tail -60 /var/lib/dhcp/dhcpd.leases
```
 
Hasil:
 
| Client | IP | Pool |
|---|---|---|
| itadori | `10.84.2.10` | Pool 1 |
| fushiguro | `10.84.2.11` | Pool 1 |
| zenin | `10.84.2.70` | Pool 2 |
| okkotsu | `10.84.2.71` | Pool 2 |
 
Tidak ada client yang memperoleh alamat pada `10.84.2.36`–`10.84.2.69`.

## Soal 5
Setiap tim lapangan memiliki durasi operasi yang berbeda. Pada Network 3, berikan short lease 30 menit (1800 detik) kepada ino dan kusakabe, serta long lease 12 jam (43200 detik) kepada miwa. Gunakan pool short lease [PREFIX IP].3.10–[PREFIX IP].3.89 dan pool long lease [PREFIX IP].3.100–[PREFIX IP].3.199. Sesuaikan default-lease-time dan max-lease-time untuk setiap kelas client. Berikan pula DHCP options berupa DNS [PREFIX IP].1.2 dan [PREFIX IP].1.3, serta domain-search <xxxx>.com.

### Ringkasan
*Network 3 dibagi dengan class `short` (ino, kusakabe; lease 1800 detik; pool `10.84.3.10`–`10.84.3.89`) dan class `long` (miwa; lease 43200 detik; pool `10.84.3.100`–`10.84.3.199`). DHCP options diberikan ke semua client: DNS `10.84.1.2` dan `10.84.1.3`, serta domain-search `K41.com`.*

### Langkah Pengerjaan
1. Menambahkan option global `domain-name-servers 10.84.1.2, 10.84.1.3` dan `domain-search "K41.com"` pada `dhcpd.conf`.
2. Mendefinisikan class `short` (MAC ino dan kusakabe) dengan `default-lease-time 1800` dan `max-lease-time 1800`, serta class `long` (MAC miwa) dengan `default-lease-time 43200` dan `max-lease-time 43200`.
3. Mengganti `range` pada subnet Network 3 dengan dua blok `pool` yang masing-masing mengizinkan class `short` dan `long`.
4. Memvalidasi konfigurasi dan me-restart service di tengen.
5. Meminta lease dari ino, kusakabe, dan miwa, lalu memeriksa lease time, `resolv.conf`, dan `dhcpd.leases`.
6. Membuktikan domain-search sampai ke client. `udhcpc` secara bawaan tidak meminta option 119 (domain-search), sehingga ditambahkan `-O 119` dan opsi yang diterima dicetak dengan script `-s`.

### Command
**tengen** — `/root/05_tengen_lease.sh` (bagian yang ditambahkan)
 
```
option domain-name-servers 10.84.1.2, 10.84.1.3;
option domain-search "K41.com";
 
class "short" {
    match if substring(hardware, 1, 6) = 02:42:7d:1f:d9:00
          or substring(hardware, 1, 6) = 02:42:65:95:ef:00;
    default-lease-time 1800;
    max-lease-time 1800;
}
class "long" {
    match if substring(hardware, 1, 6) = 02:42:90:34:fc:00;
    default-lease-time 43200;
    max-lease-time 43200;
}
 
subnet 10.84.3.0 netmask 255.255.255.0 {
    option routers 10.84.3.1;
    option broadcast-address 10.84.3.255;
 
    pool {
        range 10.84.3.10 10.84.3.89;
        allow members of "short";
    }
    pool {
        range 10.84.3.100 10.84.3.199;
        allow members of "long";
    }
}
```
 
Konfigurasi lengkap (class Network 2 dari Soal 4 tetap ada) ditulis ulang oleh script, lalu:
 
```
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server restart
```
 
**Client** (ino, kusakabe, miwa)
 
```
ip link show eth0
udhcpc -i eth0
ip -br a
cat /etc/resolv.conf
```
 
**Bukti domain-search** (kusakabe)
 
```
printf '#!/bin/sh\nenv | grep -E "^(search|domain|dns|router|subnet|broadcast|lease)"\n' > /tmp/show.sh
chmod +x /tmp/show.sh
udhcpc -i eth0 -n -q -s /tmp/show.sh              # tanpa option 119: tidak ada baris search
udhcpc -i eth0 -n -q -O 119 -s /tmp/show.sh       # dengan option 119: search=K41.com
```
 
**Verifikasi** (tengen)
 
```
cat /etc/dhcp/dhcpd.conf
dhcpd -t -cf /etc/dhcp/dhcpd.conf
tail -60 /var/lib/dhcp/dhcpd.leases
```
 
Hasil:
 
| Client | IP | Lease time | Pool |
|---|---|---|---|
| ino | `10.84.3.10` | 1800 detik (30 menit) | short |
| kusakabe | `10.84.3.11` | 1800 detik (30 menit) | short |
| miwa | `10.84.3.100` | 43200 detik (12 jam) | long |
 
`resolv.conf` ketiga client berisi `nameserver 10.84.1.2` dan `nameserver 10.84.1.3`. Pada `dhcpd.leases`, lease ino dan kusakabe berselisih 30 menit antara `starts` dan `ends`, sedangkan lease miwa berselisih 12 jam. Dengan `-O 119`, client menerima `search=K41.com`.

Catatan: angka lease time di client dapat lebih kecil dari nilai penuh (misalnya `1796`) karena client sedang memperbarui lease yang masih aktif, sehingga server mengembalikan sisa waktunya. Nilai di server tetap 1800 detik.

## Soal 6

### Ringkasan

### Langkah Pengerjaan

### Command

## Soal 7

### Ringkasan

### Langkah Pengerjaan

### Command

## Soal 8

### Ringkasan

### Langkah Pengerjaan

### Command

## Soal 9

### Ringkasan

### Langkah Pengerjaan

### Command

## Soal 10

### Ringkasan

### Langkah Pengerjaan

### Command