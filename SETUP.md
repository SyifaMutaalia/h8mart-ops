# SETUP · Stack Milestone H8Mart Quick-Commerce Ops

Estimasi 15-30 menit (unduhan image). Versi image dikunci di `.env.example` (n8n dan task runners 2.44.7, `postgres:16.15-alpine`, `node:24-alpine`, Uptime Kuma 2.5.8); jangan mengubahnya.

## 1. Prasyarat

Docker Desktop (atau Docker Engine + Compose **v2.24 atau lebih baru**, dibutuhkan `compose.vps.yaml`) berjalan, seperti Setup Phase 3. RAM bebas minimal 6 GB. Cek:

```bash
docker --version
docker compose version
```

## 2. Siapkan Folder

Buat repo public kalian di folder `h8mart-ops/` dari isi folder `set_1` (README bagian 5, langkah 1), lalu:

```bash
cd h8mart-ops
cp .env.example .env
```

PowerShell 7: `Set-Location h8mart-ops; Copy-Item .env.example .env`

Port default milestone sengaja berbeda dari stack Phase 3 lain: n8n **5690**, Uptime Kuma **3011**, PostgreSQL 5440, mock API **8080** (port umum yang sering dipakai aplikasi lain). Bila ada yang bentrok, ubah `N8N_HOST_PORT`, `KUMA_HOST_PORT`, `PG_HOST_PORT`, atau `MOCK_API_HOST_PORT` di `.env`; `N8N_WEBHOOK_URL` (dipakai Production URL dan resume URL node Wait) ikut `N8N_HOST_PORT` otomatis. Jangan mengubah `N8N_VERSION`.

## 3. Jalankan

```bash
docker compose up -d
docker compose ps
```

Semua service harus `running` (postgres `healthy`). Seed database dimuat otomatis saat volume pertama dibuat.

## 4. Verifikasi

```bash
# data terbaca: 12 merchant | 30 produk | 205 baris stok
docker compose exec -T postgres psql -U h8mart -d h8mart -At -c "SELECT (SELECT count(*) FROM core.merchants), (SELECT count(*) FROM core.products), (SELECT count(*) FROM core.merchant_stock)"
# role read-only benar-benar read-only (harus error: cannot execute INSERT in a read-only transaction)
docker compose exec -T postgres psql -U mcp_reader -d h8mart -c "INSERT INTO ops.dead_letter(workflow) VALUES ('x')"
# mock API hidup
curl -s http://localhost:8080/health
# Merchant Stock API menjawab (header X-Api-Key dari .env)
curl -s -H "X-Api-Key: h8mart-mock-key" http://localhost:8080/merchants/M001/stock
```

PowerShell 7: ganti baris `curl` dengan `Invoke-RestMethod http://localhost:8080/health` dan `Invoke-RestMethod -Uri http://localhost:8080/merchants/M001/stock -Headers @{ "X-Api-Key" = "h8mart-mock-key" }`. Port memakai nilai di `.env`.

Buka n8n di `http://localhost:5690`, buat akun owner, dan Uptime Kuma di `http://localhost:3011` (buat akun admin pertama kali). Webhook production di laptop: `http://localhost:5690/webhook/<path>`.

## 5. Dari Dalam n8n

Di dalam container, `localhost` adalah container n8n sendiri. Pakai nama service:

| Tujuan | URL / host |
| --- | --- |
| PostgreSQL | host `postgres`, port `5432`, database `h8mart` |
| Mock API | `http://mock-api:8080` |
| Uptime Kuma push | `http://uptime-kuma:3001/api/push/<token>` |
| MCP Server WF2 (endpoint production) | `http://n8n:5678/mcp/<path>`; di MCP Client Tool pilih **Server Transport `HTTP Streamable`** (aktif setelah WF2 di-Publish) |

Buat credential n8n yang **terpisah** (juga **Telegram API** untuk bot kalian, bagian 5b): PostgreSQL dengan `mcp_reader` (WF2 dan membaca di WF3: tool MCP, `core.data_info`, allowlist), PostgreSQL dengan `ops_writer` (menulis, termasuk `INSERT` `ops.tickets` di WF3), Header Auth untuk webhook, Header Auth `X-Api-Key` untuk mock API, dan **OpenAI API** (node OpenAI Chat Model, model `gpt-6-luna`). API key OpenAI dibagikan instruktur (jangan dibagikan ulang, jangan di-commit, ganti dengan placeholder di export); tempel ke credential n8n, bukan ke node. Model `gpt-6-luna` menolak **Sampling Temperature** selain bawaan, jadi biarkan Options di node OpenAI Chat Model kosong. Karena key dipakai bersama satu kelas, **hemat**: pasang Max Tries seperlunya, jalankan dev set seperlunya (bukan di setiap perubahan kecil), dan jangan membuat loop pemanggilan. Bila kalian punya key Anthropic sendiri, Anthropic Chat Model (Claude) boleh dipakai sebagai gantinya. Password dan token lain diambil dari `.env` ke credential, bukan ditulis di node; satu-satunya yang ditulis di node adalah `chat_id` Ops (bukan rahasia). Saat VPS di-terminate, hapus key dari VPS (credential dan `.env`).

## 5b. Bot Telegram H8Mart Ops

Bot ini dipakai untuk digest, alert, approval refund, dan chat asisten (touchpoint dan aturannya: [guide/telegram-bot.md](guide/telegram-bot.md)). Mengirim pesan biasa tidak butuh HTTPS, jadi bot bisa dibuat sekarang dan langsung dipakai untuk digest dan alert dari laptop; tombol approval dan chat asisten menunggu instance HTTPS (aturan: [guide/telegram-bot.md](guide/telegram-bot.md)).

1. Di Telegram, chat **@BotFather**, kirim `/newbot`, isi nama (mis. `H8Mart Ops Nama Kalian`) dan username berakhiran `bot`. BotFather memberi **token** (rahasia, jangan di-commit atau di-screenshot).
2. Di n8n: **Credentials** > **Create credential** > **Telegram API**, isi **Access Token** dengan token tadi, biarkan Base URL `https://api.telegram.org`. Simpan; tes koneksi harus hijau.
3. Buka chat dengan bot kalian di Telegram dan kirim `/start` (bot baru tidak bisa menulis ke kalian sebelum kalian memulai chat).
4. Ambil **chat_id**: chat **@userinfobot**, lalu catat angka `Id` yang dibalasnya (cara paling aman). Alternatif: kirim satu pesan ke bot kalian, lalu buka `https://api.telegram.org/bot<TOKEN>/getUpdates` dan baca `message.chat.id`; URL ini berisi token, jadi tersimpan di riwayat browser (hapus setelahnya) dan jangan masuk screenshot. `getUpdates` menjawab `409 Conflict` bila bot sudah memakai webhook (workflow Telegram Trigger sedang Published).
5. Uji dari n8n: node **Telegram** > Resource **Message** > Operation **Send Message**, Chat ID = angka tadi, Text bebas. Pesan harus muncul di HP.
6. Isi allowlist untuk WF3 (chat kalian sendiri, dipetakan ke satu merchant pilihan kalian), lewat psql sebagai superuser:

   ```bash
   docker compose exec -T postgres psql -U h8mart -d h8mart -c "INSERT INTO ops.telegram_merchants (chat_id, merchant_id, label) VALUES (123456789, 'M003', 'chat saya')"
   ```

   Ganti `123456789` dengan `chat_id` kalian. Di VPS, jalankan perintah yang sama dengan `-f compose.yaml -f compose.vps.yaml`.

Aturan HTTPS, satu webhook per bot, format pesan Markdown, dan cara menguji approval selama lokal: [guide/telegram-bot.md](guide/telegram-bot.md).

## 6. Reset

Reset data (tetap menyimpan workflow n8n): jalankan ulang seed sebagai superuser. Ini menghapus semua `ops.*` dan mengembalikan stok, order, dan tanggal ke keadaan awal.

```bash
docker compose exec -T -e PG_READER_PASSWORD=mcp-reader-lab -e PG_WRITER_PASSWORD=ops-writer-lab postgres sh -c 'for f in 01-schema 02-seed-data 03-roles; do psql -U h8mart -d h8mart -v ON_ERROR_STOP=1 -q -f /docker-entrypoint-initdb.d/$f.sql; done'
docker compose restart mock-api
```

PowerShell 7: jalankan dua perintah `docker compose` di atas apa adanya (bagian `sh -c` dijalankan di dalam container, jadi sama di semua OS). Di VPS, ganti `mcp-reader-lab` dan `ops-writer-lab` dengan nilai `PG_READER_PASSWORD` dan `PG_WRITER_PASSWORD` dari `.env` server.

Reset total, termasuk workflow n8n (**export workflow dulu**):

```bash
docker compose down -v
docker compose up -d
```

## 7. Deploy ke VPS

Instance lab Sesi 9 (W2D4) sudah di-terminate di akhir lab, jadi buat **VPS baru** khusus Milestone dengan langkah di bawah (akun AWS yang sama). Konsepnya sama dengan lab **P3W2D4 (Self-Hosted Infrastructure Setup, Practical)**: EC2 + Docker + Caddy (HTTPS otomatis) + DuckDNS. Bedanya, yang dijalankan adalah **stack milestone lengkap** (n8n + task runners, PostgreSQL `h8mart` + seed, mock API, Uptime Kuma) dan Caddy **hanya mem-proxy n8n**. Bila ada langkah klik yang lupa, buka lagi README lab P3W2D4 (Core A (langkah 1-2) untuk EC2 dan SSH, langkah 6 (DuckDNS)).

### Jendela waktu dan biaya

- Cukup **satu VPS**: buat setelah lab S09 (W2D4/W2D5, paling lambat W4D2) dan biarkan **hidup sampai instruktur memberi tahu lewat DM bahwa penilaian selesai** (penilai memanggil Production URL; nilai keluar sebelum kelas W4D5 19.00), lalu **terminate** (dan release Elastic IP bila ada). Jangan di-stop: IP publik berubah dan DuckDNS jadi salah arah.
- **Biaya ditanggung kredit AWS Free Tier akun yang sama dengan Sesi 9** (jangan membuat akun baru). Akun baru (sejak 15 Jul 2025) mendapat USD 100 kredit saat daftar + hingga USD 100 dari menyelesaikan aktivitas (maks USD 200). **Free plan tidak ada tagihan, tetapi berakhir 6 bulan setelah akun dibuat atau saat kredit habis, mana yang lebih dulu; setelah itu akun ditutup otomatis** (data disimpan 90 hari) kecuali di-upgrade ke Paid plan. Pemakaian EC2 dipotong dari kredit. Cek sisa kredit dan tanggal berakhir di AWS Billing **sebelum** membuat VPS: kredit tidak boleh habis (atau plan berakhir) sebelum penilaian selesai. **Akun lama** (dibuat sebelum 15 Jul 2025) tidak mendapat kredit ini dan ditagih pay-as-you-go sesuai estimasi di bawah, jadi Budget alert wajib dipasang.
- Pasang **AWS Budgets alert** (Billing and Cost Management > Budgets > Create budget > Zero spend budget atau Monthly cost budget dengan email kalian) supaya tidak kaget.
- Estimasi (instance `t3.small`, Jakarta, harga dicek 30 Okt 2026; hidup ±16 hari = ±384 jam, dari W2D4 sampai nilai keluar W4D5): EC2 US$0,0264/jam ≈ US$10,1; IPv4 publik US$0,005/jam ≈ US$1,9; EBS 20 GiB ±US$0,1/GB-bulan ≈ US$1,1 (±16 hari); total **≈US$13**, masih di bawah kredit. Harga bisa berubah: tulis harga dari halaman resmi AWS pada hari kalian mengerjakan di dokumen TCO.
- **Tipe instance:** tipe free-plan eligible untuk jendela ini adalah t3.micro, t3.small, t4g.micro, t4g.small, c7i-flex.large, m7i-flex.large. Stack milestone memakai ±0,75 sampai ±1,3 GiB RAM (dua pengukuran `docker stats` setelah beban uji: n8n ±480 MiB, runners 85-220, PostgreSQL 35-215, Uptime Kuma 130-255, mock API 15-115) ditambah sistem operasi dan Caddy, jadi **`t3.small` (2 GiB) pas-pasan: tambahkan swap 2 GiB**. Bila tersedia di akun kalian, **`c7i-flex.large` (4 GiB)** memberi ruang lebih (cek harga per jam di halaman resmi). `t3.micro` (1 GiB) tidak cukup. Gunakan arsitektur x86_64 (`t3`, `c7i-flex`) karena image di stack ini diuji di x86_64.

### Langkah demi langkah

Langkah 2-4 sama dengan Sesi 9; yang baru adalah langkah 5-10.

1. **Cek kredit dan pasang Budget alert** (lihat di atas).
2. **Launch EC2** (console AWS, region **Asia Pacific (Jakarta)**, perlu di-enable): nama `h8mart-ops`, AMI **Ubuntu Server 24.04 LTS**, tipe `t3.small` (atau `c7i-flex.large`), key pair baru (`.pem`, simpan aman), storage **20 GiB gp3**. Security Group: `22` hanya dari **My IP**, `80` dan `443` dari `0.0.0.0/0`; port 5690, 5440, 8080, 3011 **tidak** dibuka. Catat **Public IPv4**.
3. **SSH dan install Docker.** Di laptop:

   ```bash
   chmod 400 key.pem
   ssh -i key.pem ubuntu@<PUBLIC_IPV4>
   ```

   PowerShell 7 (Windows): `ssh -i .\key.pem ubuntu@<PUBLIC_IPV4>`; bila muncul `UNPROTECTED PRIVATE KEY FILE`, jalankan `icacls .\key.pem /inheritance:r /grant:r "$($env:USERNAME):(R)"` sekali. Di server:

   ```bash
   curl -fsSL https://get.docker.com | sudo sh
   sudo usermod -aG docker ubuntu && newgrp docker
   docker compose version
   ```

   Untuk `t3.small`, tambahkan **swap 2 GiB** (tahan reboot):

   ```bash
   sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   free -h
   ```

4. **DuckDNS:** di duckdns.org buat subdomain (mis. `h8mart-nama`), isi **current ip** dengan Public IPv4 instance, lalu cek dari laptop: `nslookup h8mart-nama.duckdns.org` harus menjawab IP itu. Domain kalian: `DOMAIN_NAME=h8mart-nama.duckdns.org`.
5. **Ambil folder repo di server.** Push dulu dari laptop, lalu di server: `git clone <URL repo public kalian> h8mart-ops` (repo public, tanpa token). `.env` lokal tidak ikut karena di-ignore git; `.env` server dibuat dari `.env.example` pada langkah berikutnya.

6. **Isi `.env` di server:**

   ```bash
   cd ~/h8mart-ops
   cp .env.example .env
   openssl rand -hex 32          # salin hasilnya untuk N8N_ENCRYPTION_KEY
   nano .env
   ```

   Ganti **semua** password (`PG_SUPERUSER_PASSWORD`, `PG_READER_PASSWORD`, `PG_WRITER_PASSWORD`), `MOCK_API_KEY`, `N8N_RUNNERS_AUTH_TOKEN`, dan `WEBHOOK_TOKEN` dengan nilai baru yang acak (minimal 32 karakter untuk token, mis. hasil `openssl rand -hex 24`; bukan nilai latihan), lalu aktifkan baris VPS: `DOMAIN_NAME`, `SSL_EMAIL` (email asli untuk Let's Encrypt, hanya di `.env` server), `N8N_ENCRYPTION_KEY`. Jangan mengubah `N8N_ENCRYPTION_KEY` setelah n8n pertama kali jalan (credential tersimpan jadi tidak terbaca), dan password database baru terpakai bila volume dibuat dari nol (`docker compose down -v` bila ingin mengganti).
7. **Jalankan stack:**

   ```bash
   docker compose -f compose.yaml -f compose.vps.yaml up -d
   docker compose -f compose.yaml -f compose.vps.yaml ps
   docker compose -f compose.yaml -f compose.vps.yaml logs caddy | tail -20
   ```

   Semua service `running` (postgres `healthy`); log Caddy memuat `certificate obtained successfully`. Hanya `caddy` membuka port ke internet (80, 443); postgres, mock API, dan Kuma hanya di 127.0.0.1. Seed database dimuat otomatis saat volume pertama dibuat. Bila sertifikat gagal: pastikan DuckDNS menunjuk ke IP yang benar dan port 80/443 terbuka di Security Group.
8. **Siapkan n8n.** Buka `https://<DOMAIN_NAME>` dan **segera** buat akun owner dengan password panjang yang unik: halaman setup owner bisa diambil siapa pun yang membukanya lebih dulu. Lalu:
   - Buat credential: PostgreSQL `mcp_reader` dan `ops_writer` (host `postgres`), Header Auth `X-H8Mart-Token` (nilai `WEBHOOK_TOKEN` baru), Header Auth `X-Api-Key` (nilai `MOCK_API_KEY` baru), **OpenAI API** (key dari instruktur), dan **Telegram API** (token bot kalian).
   - Impor `workflows/*.json` (buat workflow baru, lalu menu **⋯** di kanan atas editor › **Import** › **From file**), pilih credential di tiap node, ganti token Kuma dengan token monitor di VPS (buat lewat SSH tunnel, lihat di bawah), ganti `chat_id` Ops pada node Telegram dengan `chat_id` kalian, dan set **Error workflow** WF1-WF4 ke WF5.
   - **Publish** WF2 dan WF5 dulu, lalu WF1, WF3, WF4. Untuk chat asisten, **Publish** workflow yang memakai **Telegram Trigger**: n8n mendaftarkan webhook Production URL ke bot (webhook Telegram wajib HTTPS, sehingga baru bisa di instance ini, dan satu bot hanya punya satu webhook; pakai bot kedua untuk uji).
   - Isi allowlist `ops.telegram_merchants` (SETUP bagian 5b, dengan `-f compose.yaml -f compose.vps.yaml` di perintah `docker compose`).
   - Setelah HTTPS, pada node Telegram **Send and Wait for Response** boleh mengaktifkan **Approve Within Chat** supaya approval cukup satu ketukan di HP.
   - Uptime Kuma, mock API, dan PostgreSQL hanya terjangkau dari VPS (127.0.0.1); akses dari laptop lewat SSH tunnel: `ssh -i key.pem -L 13011:localhost:3011 -L 18080:localhost:8080 ubuntu@<PUBLIC_IPV4>`, lalu buka `http://localhost:13011` (Kuma di VPS) dan `http://localhost:18080/admin/...` (mock API di VPS). Port laptop 13011 dan 18080 dipakai supaya tidak bentrok dengan stack lokal (3011 dan 8080). Port ini **tidak** dibuka di Security Group.
9. **Verifikasi dari luar jaringan VPS** (laptop atau HP dengan data seluler):

   ```bash
   curl -s -X POST https://<DOMAIN_NAME>/webhook/<path-order> -H "X-H8Mart-Token: <token>" -H "Content-Type: application/json" -d @fixtures/event-order-created-ok.json
   ```

   PowerShell 7: `Invoke-RestMethod`, lihat `fixtures/README.md`. Jalankan sinkron stok minimal sekali, kirim pesan ke bot dari Telegram (chat asisten), dan ambil screenshot browser HTTPS, `docker compose ps`, serta `curl` untuk folder `evidence/deploy/`.
10. **Setelah nilai diumumkan:** ganti token penilaian, `docker compose -f compose.yaml -f compose.vps.yaml down -v`, hapus key OpenAI dan token bot dari credential dan `.env` server (atau revoke token bot lewat @BotFather `/revoke`), **terminate** instance, release Elastic IP (bila ada), dan cek AWS Billing.

Catatan stack: `N8N_WEBHOOK_URL` di VPS diset oleh `compose.vps.yaml` ke `https://<DOMAIN_NAME>/` sehingga Production URL dan resume URL node Wait atau Send and Wait memakai HTTPS (variabel `WEBHOOK_URL` lama tidak dipakai, deprecated sejak n8n 2.35.0).

### Plan B (hanya lokal)

Bila VPS gagal, jalankan di laptop dan kumpulkan bukti lengkap. Tanpa Production URL penilai tidak bisa menjalankan smoke test, sehingga **nilai Deployment berkurang** dan bagian lain dinilai dari evidence di repo.

## Masalah Umum

| Gejala | Penyebab | Solusi |
| --- | --- | --- |
| `port is already allocated` | port host bentrok | ubah port di `.env`, `docker compose up -d` lagi |
| postgres tidak `healthy` | volume lama dari percobaan sebelumnya | `docker compose down -v` lalu `up -d` |
| Code node gagal | `task-runners` tidak jalan | `docker compose ps`, pastikan `task-runners` running |
| Resume URL Wait memakai port salah | `N8N_WEBHOOK_URL` tidak sesuai port host | pakai `compose.yaml` apa adanya (ikut `N8N_HOST_PORT`), lalu `docker compose up -d` lagi |
| `401 unauthorized` dari mock API | header `X-Api-Key` salah/kosong | cek nilai `MOCK_API_KEY` di `.env` |
| n8n tidak bisa menjangkau database | credential memakai `localhost` | ganti host menjadi `postgres` |
| Telegram `Bad Request: chat not found` | belum `/start` ke bot, atau `chat_id` salah | kirim `/start` ke bot, ambil ulang `chat_id` lewat @userinfobot |
| `getUpdates` menjawab `409 Conflict` | bot sudah memakai webhook (workflow Telegram Trigger Published) | ambil `chat_id` lewat @userinfobot, atau unpublish workflow itu sebentar |
| MCP Client Tool gagal tersambung | WF2 belum di-Publish, URL memakai `localhost`, atau transport salah | Publish WF2, pakai `http://n8n:5678/mcp/<path>`, Server Transport `HTTP Streamable` |
| Telegram Trigger gagal aktif, atau pesan ditolak (`can't parse entities`) | aturan Telegram | lihat [guide/telegram-bot.md](guide/telegram-bot.md); masalah saat membangun workflow: [guide/common-mistakes.md](guide/common-mistakes.md) |
