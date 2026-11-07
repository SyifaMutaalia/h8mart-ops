# 03 · TCO 12 Bulan + Keputusan Deployment · H8Mart Quick-Commerce Ops

**Nama:** [isi nama peserta]
**Tanggal penyusunan:** 7 November 2026
**Sumber:** Handson Week 2 Day 3 (tabel asumsi harga, diperiksa dalam modul 2 Nov 2026); AWS Free Tier & EC2, n8n Pricing. Lihat tautan sumber di akhir dokumen. **Semua biaya adalah simulasi**, bukan hasil invoice.

## 1. Opsi yang Dibandingkan

| Opsi | Bentuk | Biaya awal | Biaya bulanan | Biaya 12 bulan | Catatan kepatuhan / data |
| --- | --- | ---: | ---: | ---: | --- |
| Cloud (n8n Cloud Enterprise, estimasi) | SaaS; plan Enterprise karena diasumsikan 35.000 workflow executions/bulan | USD 0 | USD 720 langsung + USD 7,50 personil | **USD 8.830** termasuk risiko setahun USD 100 | Harga Enterprise **bukan penawaran resmi**; rujukan harga kapasitas 40.000 pada lab tidak sama dengan n8n Cloud Enterprise |
| Self-hosted (AWS EC2 Jakarta + Docker Compose) | EC2 `t3.small`, EBS gp3 20 GiB, public IPv4, Caddy, n8n + runner + PostgreSQL + Mock API + Kuma | USD 0* | USD 25 langsung + USD 60 personil | **USD 1.560** termasuk biaya operasional USD 240/tahun dan risiko USD 300/tahun | Region Jakarta; PostgreSQL, log dan secrets di server; batasi Security Group; perlindungan data pelanggan |
| On-premise (server H8Mart) | Server kantor, pengelolaan internal | USD 0* | USD 210 langsung (amortisasi 150, listrik/jaringan 60) + USD 180 personil | **USD 6.080** termasuk operasional USD 900/tahun dan risiko USD 500/tahun | Kendali lokal tinggi tetapi backup, keamanan fisik dan tenaga teknis ditanggung H8Mart |

*`Biaya awal USD 0` adalah **asumsi pembukuan lab** karena pembelian server on-premise diamortisasi ke biaya bulanan; bukan berarti tidak ada pengeluaran awal. Biaya setup internal dihitung lewat kategori personil.

**Asumsi volume H8Mart (belum terukur):** 35.000 eksekusi workflow per bulan = 2.880 sinkron stok (setiap 15 menit selama 30 hari) + 25.000 event order + 5.000 event delivery/refund + 2.120 interaksi merchant/operasional/monitoring. Ini asumsi untuk analisis kapasitas dan perbandingan biaya, bukan hasil performance test. Satu siklus sync yang memproses 12 merchant tetap dihitung **satu eksekusi** workflow.

**Rumus TCO 12 bulan dari Day 3:**

`(biaya langsung bulanan × 12) + (jam personil/bulan × USD 15 × 12) + biaya operasional tahunan + biaya risiko tahunan`

- AWS: `(25×12) + (4×15×12) + 240 + 300 = 1.560 USD`.
- Cloud: `(720×12) + (0,5×15×12) + 0 + 100 = 8.830 USD`.
- On-premise: `(210×12) + (12×15×12) + 900 + 500 = 6.080 USD`.
- Selisih AWS vs Cloud = **USD 7.270**; kurs ilustratif `USD 1 = Rp16.500`, sehingga selisih **Rp119.955.000**.

**Rincian self-hosted AWS** dari tabel Day 3: EC2 t3.small USD 0,0264/jam × 730 jam ≈ USD 19,27; EBS gp3 20 GiB × USD 0,096 ≈ USD 1,92; public IPv4 USD 0,005/jam × 730 jam ≈ USD 3,65; total USD 24,84, **dibulatkan USD 25/bulan**. Tarif ini asumsi referensi latihan, bukan jaminan invoice. Biaya backup, transfer keluar, snapshot, domain berbayar, pajak, dan kredit Free Tier harus diperiksa terpisah.

**Free Tier:** Untuk akun AWS baru pada/ setelah 15 Juli 2025, `t3.small` termasuk jenis EC2 yang dapat memenuhi skema Free Tier berbasis kredit. Kredit awal USD 100 dapat berlaku, tetapi **jumlah aktual, tanggal kedaluwarsa, dan kondisi akun wajib dicek di Billing**. Kredit **bukan** pengurangan TCO teknis 12 bulan dan **tidak** membuat operasional/risiko/personil gratis. Jika kredit terpakai USD 100 sepenuhnya untuk biaya AWS pada periode yang memenuhi ketentuan, arus kas infrastruktur AWS berkurang maksimal USD 100; jumlah riil tidak diketahui sebelum cek billing. Free Plan maksimal 6 bulan atau sampai kredit habis (mana yang lebih dulu), bukan 12 bulan gratis.

**Sensitivitas:** Bila jumlah eksekusi hanya 8.000/bulan, berdasarkan asumsi Day 3 n8n Cloud Pro: `54×12 + 0,5×15×12 + 100 = USD 838`, lebih murah daripada AWS USD 1.560. Pemilihan EC2 **tidak dapat didasarkan pada penghematan biaya** dalam skenario 8.000/bulan.

## 2. Keputusan & Justifikasi

**Dipilih self-hosted AWS EC2 Jakarta untuk milestone H8Mart**, karena (1) tugas mengharuskan integrasi dan pembuktian stack multi-container `n8n + Python runner + PostgreSQL + Mock API + Uptime Kuma`, yang lebih mudah dikendalikan pada server sendiri, dan (2) workflow dapat menerima webhook publik HTTPS untuk pengujian instruktur serta menerapkan role database dan monitoring end-to-end. Dalam simulasi volume 35.000 eksekusi/bulan, opsi ini juga memiliki TCO terendah.

**Syarat kepatuhan:** Batasi akses ke database pesanan dan data pelanggan, minimalkan data pribadi pada alert/log, simpan kredensial di n8n Credentials / `.env` server (bukan repo), jaga backup, kontrol akses, dan kebijakan retensi. Kewajiban pemrosesan data pribadi harus ditinjau sesuai UU 27 Tahun 2022 tentang Pelindungan Data Pribadi; **dokumen ini tidak menyatakan kewajiban lokasi data khusus** tanpa kajian hukum lebih lanjut.

## 3. Rencana Deployment (final)

| Item | Nilai |
| --- | --- |
| Penyedia & spesifikasi instance | **AWS EC2 ap-southeast-3 (Jakarta)**, Ubuntu Server 24.04 LTS, `t3.small` (2 vCPU, 2 GiB, x86_64) untuk akun Free Tier baru yang memenuhi kriteria; 20 GiB gp3, swap 2 GiB. Ukuran ini minimal, pantau OOM/CPU. |
| `compose.yaml`: service yang dijalankan | `n8n`, `task-runners`, `postgres`, `mock-api`, `uptime-kuma`; ditambah `caddy` melalui `compose.vps.yaml`. Jalankan keduanya bersama dari EC2. |
| Variabel penting di `.env` (tanpa nilai rahasia) | `DOMAIN_NAME`, `SSL_EMAIL`, `N8N_ENCRYPTION_KEY`, `N8N_RUNNERS_AUTH_TOKEN`, `PG_SUPERUSER_PASSWORD`, `PG_READER_PASSWORD`, `PG_WRITER_PASSWORD`, `MOCK_API_KEY`, `WEBHOOK_TOKEN`, `N8N_VERSION`, retensi `EXECUTIONS_DATA_*`. |
| Database n8n | **SQLite bawaan** pada Docker volume `n8n_data` sesuai `set_1`; **PostgreSQL** terpisah pada `pg_data` menyimpan `core.*` dan `ops.*` H8Mart. |
| HTTPS (domain + reverse proxy + sertifikat) | Domain/subdomain DuckDNS → public IPv4 EC2 → `Caddy` menerbitkan sertifikat otomatis untuk `https://[SUBDOMAIN].duckdns.org`. |
| Production URL yang dipanggil penilai | `https://[SUBDOMAIN].duckdns.org/webhook/[PATH_WF1_WF3_WF4]` **belum dapat diisi sebelum WF1/3/4 dibuat dan dipublish**. Header Auth `X-H8Mart-Token`. Path akhir disalin dari webhook Production masing-masing workflow. |
| Backup (apa, seberapa sering, uji restore) | Dump PostgreSQL `h8mart` + backup volume n8n/credential dan file konfigurasi, setiap hari selama pengujian, simpan terenkripsi di luar instance. Uji restore **belum dilakukan**; catat hasilnya di `evidence/deploy/`. Jangan unggah backup mengandung data rahasia ke repo publik. |

## 4. Bukti Verifikasi

> Bukti **belum ada**, karena instance AWS milik peserta belum diakses/dijalankan dari paket ini. Isikan setelah uji sungguhan. Jangan menandai status selesai berdasarkan contoh.

| Bukti | File |
| --- | --- |
| EC2 `running`, region Jakarta, SG (tanpa secrets) | `evidence/deploy/01-ec2-running.png` (belum diambil) |
| `docker compose -f compose.yaml -f compose.vps.yaml ps` | `evidence/deploy/02-compose-ps.png` (belum diambil) |
| Browser n8n HTTPS valid | `evidence/deploy/03-https-owner.png` (belum diambil) |
| Panggilan Production URL dengan respons berhasil | `evidence/deploy/04-webhook-success.png` (belum diambil) |
| Restart container tanpa kehilangan workflow/database | `evidence/deploy/05-persistence.png` (belum diambil) |

### Sumber harga dan ketentuan

- [Handson Day 3, README – Tabel Asumsi Harga](../referensi-instruktur/day3/README.md) (angka yang diadopsi dari lab tanggal 2 Nov 2026).
- [AWS EC2 On-Demand](https://aws.amazon.com/ec2/pricing/on-demand/), [AWS EBS](https://aws.amazon.com/ebs/pricing/), [AWS Public IPv4](https://aws.amazon.com/blogs/aws/new-aws-public-ipv4-address-charge-public-ip-insights/).
- [AWS EC2 Free Tier](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-free-tier-usage.html) (ketentuan bergantung tanggal akun dibuat).
- [n8n Pricing](https://n8n.io/pricing/) (Enterprise custom price; asumsi lab tidak otomatis harga resmi).
