# MULAI DI AWS EC2 — Milestone 3 H8Mart `set_1`

**Target:** semua dikerjakan langsung pada 1 instance AWS EC2. Laptop hanya dipakai membuka AWS Console/GitHub/n8n dan (opsional) mengunggah repo, **tidak menjalankan Docker/n8n lokal**. Isi `README.md` dan `guide/` dari instruktur **dipertahankan**.

## Tahap A — Buat instance (jangan buat di dua tempat)

1. AWS Console → **Billing**: cek saldo kredit dan sisa hari Free Plan; atur AWS Budget alert dan metode penghentian setelah dinilai. Akun baru sejak 15 Jul 2025 dapat memakai kredit Free Tier untuk EC2 yang eligible; pilihannya berbeda untuk akun lama. Bila saldo tidak cukup hingga penilaian, jangan menganggap instance gratis.
2. EC2 → region `Asia Pacific (Jakarta) ap-southeast-3` → Launch instance `h8mart-ops` → Ubuntu Server **24.04 LTS x86_64** → tipe `t3.small` (**bila sesuai Free Tier akun**, lihat label di Console) → disk **20 GiB gp3**. Gunakan key pair baru (simpan private key aman).
3. Security group inbound: **22/TCP My IP saja** (opsional jika EC2 Instance Connect didukung), **80/TCP** dan **443/TCP** dari `0.0.0.0/0`. Jangan buka 5690, 5678, 5432, 5440, 8080, 3001, atau 3011. EC2 Instance Connect melalui console mungkin membutuhkan aturan sumber IP layanan yang berbeda; jika SSH Console ditolak, sesuaikan sesuai dokumentasi AWS atau gunakan SSH dari IP kamu.
4. Advanced details → **User data**: kamu boleh tempel isi `aws-ec2/bootstrap-ubuntu.sh` (tanpa secrets). Ini memasang Docker, git dan swap otomatis saat boot. Alternatif: setelah Connect via browser, jalankan script secara manual (perintah di bagian B).
5. Catat public IPv4 → buat domain `nama-kamu.duckdns.org` di duckdns.org → arahkan A record ke IP itu. **Public IP dapat berubah setelah stop/start** (bukan reboot); bila berubah update DNS. Caddy butuh A record benar sebelum HTTPS sukses.

## Tahap B — Masuk langsung ke EC2

EC2 → Instances → pilih `h8mart-ops` → **Connect** → **EC2 Instance Connect**. Setelah shell Ubuntu tampil (bukan terminal Windows lokal), jalankan:

```bash
sudo apt-get update -y
sudo apt-get install -y git curl unzip ca-certificates
curl -fsSL https://get.docker.com | sudo sh
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
printf '/swapfile none swap sw 0 0\n' | sudo tee -a /etc/fstab
sudo docker compose version
free -h
```

**Jangan jalankan blok ini dua kali utuh**: swapfile sudah ada pada pemanggilan berikutnya; bila bootstrap user data sudah sukses, cukup cek `sudo docker compose version` dan `free -h`.

## Tahap C — Taruh repo set_1 di EC2 (bukan run lokal)

Repositori yang akan dinilai **harus public**. Cara termudah: buat repo GitHub dan unggah isi folder proyek yang telah diekstrak dari ZIP ini lewat browser GitHub (**tidak termasuk `.env`**), lalu di terminal EC2:

```bash
cd /home/ubuntu
git clone https://github.com/USERNAME/REPO.git h8mart-ops
cd h8mart-ops
ls -la
```

Jika nama struktur yang terunggah masih `H8Mart_Milestone3_AWS_EC2_set_1/`, masuk ke dalam folder tersebut sebelum menjalankan compose. Repo public hanya berisi template, konfigurasi tanpa secrets, dokumen dan workflow yang telah disanitasi. Bila repo belum dibuat, gunakan menu GitHub `New repository` → `Add file` → `Upload files` (upload **isi folder**, bukan file ZIP tunggal) dan commit. Setelah upload, EC2 melakukan clone; n8n tetap tidak berjalan di laptop.

## Tahap D — Konfigurasi dan jalankan seluruh stack H8Mart di EC2

```bash
cd ~/h8mart-ops
cp .env.example .env
openssl rand -hex 32   # buat kunci untuk N8N_ENCRYPTION_KEY
openssl rand -hex 24   # ulangi untuk tiap token/password
nano .env
```

Ganti placeholder latihan untuk `PG_SUPERUSER_PASSWORD`, `PG_READER_PASSWORD`, `PG_WRITER_PASSWORD`, `MOCK_API_KEY`, `N8N_RUNNERS_AUTH_TOKEN`, `WEBHOOK_TOKEN`. Aktifkan 3 variabel VPS (`DOMAIN_NAME`, `SSL_EMAIL`, `N8N_ENCRYPTION_KEY`). Jangan menaruh API key OpenAI atau token Telegram di `.env`/repo; buat di menu Credentials n8n. Jangan pernah bagikan isi `.env` atau kunci pemulihan dalam chat/screenshot.

```bash
sudo docker compose -f compose.yaml -f compose.vps.yaml config --quiet
sudo docker compose -f compose.yaml -f compose.vps.yaml up -d
sudo docker compose -f compose.yaml -f compose.vps.yaml ps
sudo docker compose -f compose.yaml -f compose.vps.yaml logs --tail=60 caddy
sudo docker compose -f compose.yaml -f compose.vps.yaml exec -T postgres \
  psql -U h8mart -d h8mart -c 'SELECT count(*) AS merchants FROM core.merchants;'
```

Output target query `merchants = 12`, postgres `healthy`, editor n8n dapat diakses di `https://SUBDOMAIN.duckdns.org` dengan TLS valid. Bila HTTPS gagal, periksa DNS, port 80/443, waktu UTC pada server, dan log Caddy. **Buka HTTPS lalu buat owner segera** agar orang lain tidak mendaftarkan akun owner pada instance yang masih kosong.

## Tahap E — Kerjakan 5 workflow di n8n server

1. Buat bot Telegram dari @BotFather dan catat chat_id Ops. Buat credentials n8n: `Postgres mcp_reader` (baca), `Postgres ops_writer` (tulis), Header Auth `X-Api-Key`, Header Auth `X-H8Mart-Token`, Telegram API, OpenAI API. Host PostgreSQL **`postgres:5432`**, Mock API **`http://mock-api:8080`**, bukan localhost.
2. **WF5:** import `workflows/wf5-reliability-monitoring.json`, pasang Telegram dan Header Auth Mock API untuk log; jalankan test dengan WF sumber yang published; baca `docs/07-alerting-dan-log-day5.md`.
3. **WF2:** bangun tiga tools read-only (MCP) sesuai `guide/wf2-merchant-data-tools.md`; jangan buka endpoint MCP publik karena Caddy memblokirnya.
4. **WF1:** sinkron 12 merchant/15 menit, proses order webhook, digest 07.00, retry, dead-letter, silent failure, heartbeat, durasi. Panduan `guide/wf1-stock-sync-order-intake.md`.
5. **WF3:** webhook pertanyaan merchant, AI Agent+MCP tools WF2, guardrail dan tiket eskalasi ke CS. Panduan `guide/wf3-ai-merchant-assistant.md`.
6. **WF4:** event `delivery.late` dan `order.failed`, voucher/refund idempotent, approval Ops Telegram. Panduan `guide/wf4-compensation-refund.md`.
7. Di WF1–WF4: Workflow settings → **Error Workflow** = `WF5 · Reliability & Monitoring H8Mart`, Timezone `Asia/Jakarta`, Save dan Publish. Setelah verifikasi, export final 5 JSON ke `workflows/` (ganti placeholder credential, token dan nilai pribadi sebelum push).

`workflows/wf5-reliability-monitoring.json` adalah **starter impor**, belum teruji pada instance AWS kamu. WF1–WF4 **belum ada export jadi** di paket agar tidak memberikan kesan seolah workflow tugas sudah selesai.

## Tahap F — Bukti dan serah tugas

Kumpulkan: screenshot EC2 Running Jakarta, Compose PS, HTTPS, webhook success, 5 canvas Published, 5 halaman Executions, SQL/data after testcase, Telegram alert & digest & approval, log severity, Uptime Kuma Up/Down, dan hasil TCO. Contoh nama file tersedia di `evidence/CEKLIST-BUKTI-AWS.md`.

**Catatan Deadline:** instans harus tetap berjalan sampai penilaian selesai; jangan stop/terminate sebelum instruktur konfirmasi. Setelah penilaian, revoke secrets, backup sesuai kebutuhan, terminate EC2, lepaskan Elastic IP jika teralokasi, hapus snapshot/volume yang tidak diperlukan, dan cek Billing. Beberapa biaya dapat tetap timbul ketika instance dihentikan.
