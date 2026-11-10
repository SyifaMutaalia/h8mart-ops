# 03 · TCO 12 Bulan + Keputusan Deployment · H8Mart Quick-Commerce Ops

**Nama:** Syifa Mutaalia  
**Tanggal revisi:** 10 November 2026  
**Basis angka:** simulasi Hands-on Phase 3 Week 2 Day 3 dalam paket awal, ditambah rujukan publik AWS dan n8n. **Bukan invoice AWS, bukan penawaran resmi n8n Enterprise, dan bukan tarif instance aktual yang sudah dibuktikan.**

## 1. Opsi yang Dibandingkan

Model perbandingan **35.000 eksekusi/bulan** adalah asumsi kapasitas; tidak diambil dari penggunaan aktual n8n. Jumlah 35.000 terdiri atas 2.880 sinkronisasi/30 hari (96 per hari), 25.000 event order, 5.000 event kompensasi/refund dan 2.120 pertanyaan/interaksi. H8Mart pada milestone masih menggunakan data sintetis.

| Opsi | Bentuk | Biaya awal | Biaya bulanan | Biaya 12 bulan | Catatan kepatuhan / data |
| --- | --- | ---: | ---: | ---: | --- |
| Cloud (n8n Enterprise, *asumsi lab*) | SaaS, alokasi kapasitas 35.000 eksekusi; **USD 720/bulan adalah asumsi latihan, bukan harga resmi** | USD 0* | USD 720 layanan + USD 7,50 personel | **USD 8.830** (termasuk risiko USD 100/tahun) | Hosting data dan pengaturan kontrol akses mengikuti kontrak penyedia; perlu penawaran resmi untuk angka final. |
| Self-hosted (AWS EC2 + Compose, *simulasi lab*) | EC2 `t3.small` dan layanan Caddy, n8n, runners, PostgreSQL, Mock API, Kuma | USD 0* | USD 25 langsung + USD 60 personel | **USD 1.560** (termasuk operasional USD 240 + risiko USD 300/tahun) | Data dan kredensial dikelola sendiri; tuntut backup, kontrol akses, retensi dan pemantauan. |
| On-premise (server H8Mart, *asumsi*) | Server dimiliki perusahaan; amortisasi dan listrik sendiri | USD 0* | USD 210 langsung + USD 180 personel | **USD 6.080** (termasuk operasional USD 900 + risiko USD 500/tahun) | Kontrol fisik lebih besar; biaya maintenance dan pemulihan menjadi tanggung jawab organisasi. |

*Asumsi biaya awal USD 0 menganggap investasi dicatat lewat amortisasi/biaya bulanan. Implementasi nyata dapat memiliki biaya setup awal.

**Rumus yang digunakan (USD):**  
`TCO_12_bulan = 12 × (biaya_langsung_bulanan + jam_admin_per_bulan × 15) + biaya_operasional_tahunan + biaya_risiko_tahunan`

- **Cloud:** `(720 + 0,5 × 15) × 12 + 100 = USD 8.830`.
- **Self-hosted (model Day 3):** `(25 + 4 × 15) × 12 + 240 + 300 = USD 1.560`.
- **On-premise:** `(210 + 12 × 15) × 12 + 900 + 500 = USD 6.080`.
- Selisih Cloud dan self-hosted pada *skenario yang sama* = **USD 7.270 per 12 bulan**. Kurs ilustratif bila diperlukan: **USD 1 = Rp16.500** (asumsi perencanaan, bukan kurs riil tanggal revisi) → Rp119.955.000.

### Rincian model AWS self-hosted (tipe instance sesuai implementasi; tarif tetap simulasi)

Model Day 3 menggunakan tipe `t3.small`, **sama dengan instance EC2 yang digunakan peserta**: EC2 **USD 0,0264/jam × 730 ≈ USD 19,27**; EBS gp3 20 GiB **USD 0,096/GiB-bulan × 20 = USD 1,92**; IPv4 publik **USD 0,005/jam × 730 = USD 3,65**; subtotal **≈ USD 24,84 → USD 25/bulan**. Nilai instance/EBS di sini **asumsi latihan**; region, family, OS, kredit, pajak, snapshot, transfer keluar dan tagihan nyata bisa berbeda. Tarif publik IPv4 USD 0,005/jam dijelaskan pada [AWS VPC Pricing](https://aws.amazon.com/vpc/pricing/).

**Implementasi peserta:** pengujian proyek menggunakan AWS EC2 **`t3.small`** (Ubuntu Server 24.04 LTS; 2 vCPU, 2 GiB RAM), sesuai konfirmasi peserta. Jadi, **tipe instance pada perbandingan TCO sama dengan tipe yang digunakan di server**. Namun, tarif EC2 USD 0,0264/jam, kapasitas EBS 20 GiB, harga EBS, dan total USD 25/bulan masih **asumsi model Day 3**, bukan tagihan aktual: region, EBS terpasang, IP publik, kredit AWS, pajak dan pemakaian perlu dilihat di AWS Billing/EC2 Console. Pantau `docker stats`, OOM dan kinerja workflow agar kapasitas 2 GiB cukup untuk semua container.

**Skema Free Tier:** untuk akun yang dibuat pada/ setelah 15 Juli 2025, AWS menerapkan Free Tier berbasis kredit (USD 100 saat daftar dan potensi tambahan USD 100), dengan opsi Free plan maksimal enam bulan atau hingga kredit habis. Syarat bergantung status akun dan tidak boleh diasumsikan berlaku untuk semua peserta. Periksa kredit di Billing; kredit mengurangi *out-of-pocket* selama masih tersedia, bukan total biaya sumber daya jangka panjang. Rujukan: [AWS Free Tier](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier.html) dan [EC2 Free Tier](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-free-tier-usage.html).

**Catatan opsi cloud:** [n8n Pricing](https://n8n.io/pricing/) memuat paket resmi dan ketentuan eksekusi yang dapat berubah; paket Enterprise **Contact Sales** sehingga USD 720/bulan di tabel bukan angka n8n yang diverifikasi. Perbandingan resmi memerlukan quotation sesuai fitur, retensi, dan volume. Opsi self-hosted Community Edition tidak memiliki biaya berlangganan n8n dalam skenario tugas, tetapi tetap memerlukan server dan pengelolaan.

**Sensitivitas:** pada 20% volume/skenario manfaat ROI, manfaat tenaga bulanan dapat lebih rendah daripada biaya total operasi. Biaya aktual OpenAI ditambahkan terpisah berdasarkan penggunaan dan model; contoh tarif token hipotesis di dokumen 02 tidak boleh menjadi nilai invoice.

## 2. Keputusan & Justifikasi

**Dipilih self-hosted AWS EC2 + Docker Compose untuk Milestone 3**, karena (1) komponen n8n, PostgreSQL, Mock API, Uptime Kuma, task runners dan Caddy perlu dihubungkan dalam satu jaringan Docker yang dapat dikendalikan; (2) instruktur dapat mengakses Production Webhook HTTPS melalui DuckDNS, tanpa akses editor n8n atau database; (3) pengelolaan role `mcp_reader`/`ops_writer`, log dan backup bisa diuji. Perbandingan TCO di atas merupakan *justifikasi skenario*, bukan jaminan EC2 paling murah pada semua volume.

**Syarat perlindungan data:** simpan token di n8n Credentials / `.env` server, gunakan HTTPS, batasi PostgreSQL/Mock API ke jaringan internal, minimalkan data pelanggan dalam alert dan repo, terapkan backup terenkripsi, retensi eksekusi, dan kontrol akses SSH. Semua data H8Mart saat milestone ini sintetis; produksi membutuhkan penilaian risiko dan kebijakan data tersendiri.

## 3. Rencana Deployment (final)

| Item | Nilai |
| --- | --- |
| Penyedia & spesifikasi instance | **Aktual yang dikonfirmasi peserta:** AWS EC2 `t3.small` (2 vCPU, 2 GiB RAM), Ubuntu Server 24.04 LTS. **Region, EBS, swap, dan kapasitas tersisa harus diverifikasi di AWS Console/`docker stats`.** Model TCO memakai tipe instance yang sama, namun nilai USD tetap estimasi. |
| `compose.yaml`: service yang dijalankan | `n8n`, `task-runners`, `postgres`, `mock-api`, `uptime-kuma`; `compose.vps.yaml` menambah `caddy` HTTPS. Gunakan `docker compose -f compose.yaml -f compose.vps.yaml ...`. |
| Variabel penting di `.env` (tanpa nilai rahasia) | `DOMAIN_NAME`, `SSL_EMAIL`, `N8N_ENCRYPTION_KEY`, `N8N_RUNNERS_AUTH_TOKEN`, `PG_SUPERUSER_PASSWORD`, `PG_READER_PASSWORD`, `PG_WRITER_PASSWORD`, `MOCK_API_KEY`, `WEBHOOK_TOKEN`, `N8N_VERSION`, variabel retensi `EXECUTIONS_DATA_*`. **Nilainya jangan di-commit.** |
| Database n8n | Volume internal n8n untuk konfigurasi/workflow (default paket menggunakan SQLite); **PostgreSQL service** untuk tabel `core.*` dan `ops.*` H8Mart. |
| HTTPS (domain + reverse proxy + sertifikat) | `https://h8mart-syifa.duckdns.org` melalui Caddy; 80/443 publik, port 5678/5432/8080/3001 tidak perlu dibuka publik. Cek sertifikat dan `curl -I`. |
| Production URL yang dipanggil penilai | WF1: `https://h8mart-syifa.duckdns.org/webhook/h8mart/order-created`; WF3: `https://h8mart-syifa.duckdns.org/webhook/h8mart/merchant-assistant`; WF4: **salin tepat dari node `Terima Event` Webhook**, karena path final belum diverifikasi. Semua dilindungi Header Auth `X-H8Mart-Token`. |
| Jadwal | WF1A setiap 15 menit, WF1C 07.00 WIB, timezone workflow **Asia/Jakarta** dan harus Published. **Setelah evidence lengkap**, instruktur memperbolehkan `Deactivate` hanya kedua Schedule Trigger lalu **Publish ulang** WF1 agar Webhook WF1 tetap bisa di-smoke-test; lihat `guide/submission.md`. |
| Backup (apa, frekuensi, uji restore) | Rencana: PostgreSQL `pg_dump`, volume n8n termasuk encryption key, file Compose/Caddy dan konfigurasi (di luar repo publik); backup terenkripsi harian saat fase pengujian, simpan terpisah. **Restore belum terkonfirmasi pernah diuji.** Hindari `docker compose down -v` karena menghapus volume. |
| Biaya dan monitoring | AWS Budgets email 50/80/100% dari limit mis. USD 5; cek Billing/Credits setiap hari pengujian. Budget memberi alarm, **tidak otomatis memblokir tagihan**. |

## 4. Bukti Verifikasi

**Status paket dokumentasi ini:** screenshot operasional asli **belum disertakan**. Path berikut merupakan daftar **evidence yang harus ditempel dari AWS/n8n peserta**, bukan klaim file sudah ada.

| Bukti | File yang perlu dibuat |
| --- | --- |
| EC2 running, instance type dan security group (tanpa rahasia) | `evidence/deploy/01-ec2-running.png` |
| `docker compose -f compose.yaml -f compose.vps.yaml ps` | `evidence/deploy/02-compose-ps.png` |
| n8n terbuka melalui HTTPS dan sertifikat valid | `evidence/deploy/03-https-valid.png` |
| Webhook WF1/WF3 dan WF4 benar-benar merespons dari jaringan luar | `evidence/deploy/04-production-webhook.png` |
| Uji restart container tetap mempertahankan workflow dan data | `evidence/deploy/05-persistence.png` |
| AWS Cost Explorer/Budgets tanpa informasi rekening | `evidence/deploy/06-aws-budgets.png` |
| Pengukuran `docker stats` / memory EC2 bila instance kecil | `evidence/deploy/07-resource-usage.png` |

### Sumber angka dan harga (rujukan untuk cek ulang pada pengumpulan)

- Materi Hands-on Day 3 tersimpan pada paket tambahan: `docs/06-rekomendasi-tco-day3.md` dan `referensi-instruktur/day3/` bila folder tersedia.
- [AWS EC2 On-Demand Pricing](https://aws.amazon.com/ec2/pricing/on-demand/)
- [AWS EBS Pricing](https://aws.amazon.com/ebs/pricing/)
- [AWS VPC Public IPv4 Pricing](https://aws.amazon.com/vpc/pricing/)
- [AWS Free Tier (Billing)](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier.html)
- [n8n Pricing](https://n8n.io/pricing/)
