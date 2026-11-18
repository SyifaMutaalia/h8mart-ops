# 04. Integration Readiness & System Compatibility — H8Mart

**Tanggal revisi:** 19 November 2026  
**Lingkungan:** AWS EC2 `t3.small`, Ubuntu 24.04, Docker Compose, n8n, PostgreSQL, Mock API, Caddy HTTPS, Uptime Kuma  
**Cakupan:** WF1–WF5; API, database, keamanan akses, dan operasional.  
**Prinsip penilaian:** Hasil yang dilaporkan tidak otomatis menjadi bukti terlampir. Status **Terbukti** hanya dipakai jika evidence dapat dibuka dan cocok dengan klaim; **Perlu lampiran** berarti hasil dilaporkan tetapi path belum diverifikasi; **Belum diuji** berarti kriteria belum didemonstrasikan; **Perlu tindakan** berarti kontrol operasional belum selesai.

## 1. Ringkasan bukti dasar

- Sinkronisasi WF1A pernah melaporkan 12 merchant, 11 berhasil, dan 188 baris diproses. Query kualitas stok yang dilaporkan menghasilkan **205 baris, 0 `product_id` NULL, 0 pasangan (`merchant_id`, `product_id`) duplikat**. Bukti terminal/SQL final harus dilampirkan.
- WF1C pernah menghasilkan digest tanggal data 7 November 2026: 162 order, 25 batal, 134 terkirim, 111 tepat waktu, cancel rate 15,43%, SLA 82,84%. Pemeriksaan kondisi `Digest Kosong?` harus memakai execution terbaru.
- WF2 dilaporkan mengembalikan data M003 dan membatasi `mcp_reader` pada operasi baca. Bukti penolakan INSERT perlu menyertakan error izin yang tepat, bukan error sintaks/kolom.
- WF3 dilaporkan menjawab pertanyaan merchant dan pernah membuat tiket fallback (`ticket_id=4`, alasan `ai_error`). Field `status` dalam respons, jalur eskalasi, serta Error Workflow harus ditunjukkan dari eksekusi terbaru.
- WF4 dilaporkan menghasilkan voucher `VC-00001` untuk `HM-SP-001`. Bukti approval/reject, refund besar, dan idempotensi harus dilampirkan sebelum menyatakan semua skenario lulus.
- WF5 telah dikonfigurasi sebagai jalur alert; perlu evidence Error Trigger yang benar-benar terpicu dari workflow sumber dan bukti notifikasi.
- Screenshot AWS menunjukkan region **Asia Pacific (Jakarta)**, **2 EC2 running**, **2 volume**, serta **USD 6,80 pada panel EC2 cost untuk Past 6 months (Global)**. Angka biaya ini bukan bukti performa ataupun biaya khusus satu instance H8Mart.

## 2. Matriks readiness: bukti per baris

**Keterangan path:** Semua lokasi di bawah adalah **target penempatan evidence**, bukan pernyataan bahwa berkas sudah ada. Ganti status menjadi **Terbukti** setelah file dan isinya diperiksa.

### A. API Readiness

| ID | Kriteria dan temuan | Bukti yang wajib ditautkan | Status saat revisi |
|---|---|---|---|
| A1 | Kontrak endpoint Merchant Stock, Notification, Order, WF3 dan WF4 tersedia pada `data-contract.md`/panduan; beberapa endpoint sudah dipanggil. | `data-contract.md`; `evidence/wf1/` screenshot request/response; `evidence/wf3/` dan `evidence/wf4/` webhook | Perlu lampiran |
| A2 | Endpoint internal dan webhook produksi dilaporkan dapat diakses. Ketersediaan harus diuji dari luar VPS, bukan hanya node n8n. | `evidence/deploy/03-https-valid.png`; `evidence/deploy/04-production-webhook.png` (URL, HTTP status, waktu) | Perlu lampiran |
| A3 | Merchant Stock diharapkan memuat `merchant_id`, `as_of`, `items`; WF3 wajib mengembalikan `status` sesuai kontrak serta field respons lainnya. | `evidence/wf1/merchant-response.png`; `evidence/wf3/response-status.png`; contoh respons sukses dan eskalasi | Perlu verifikasi WF3 |
| A4 | M009 mengembalikan 500; retry, dead-letter dan alert harus dibuktikan. Order harus diuji untuk 200/409/422 dan duplikasi. | `evidence/wf1/stock-calls.png`; `evidence/wf1/dead-letter.png`; `evidence/wf1/order-status-cases.png`; execution retry | Perlu lampiran dan retest |

**Kesimpulan API:** Ada implementasi dan hasil pengujian yang dilaporkan; status API untuk Milestone baru dapat dinyatakan terbukti setelah bukti A1–A4 dapat ditelusuri.

### B. Data & Database Readiness

| ID | Kriteria dan temuan | Bukti yang wajib ditautkan | Status saat revisi |
|---|---|---|---|
| D1 | Skema `core` dan `ops` digunakan oleh stok, order, MCP, tiket dan dead-letter. | `evidence/sql/01-schema.png` (daftar tabel dan skema) | Perlu lampiran |
| D2 | Kolom yang dibutuhkan tersedia untuk query utama. | `evidence/sql/02-columns.png` (struktur tabel yang digunakan) serta executions query sukses | Perlu lampiran |
| D3 | Query yang dilaporkan: total stok 205; `product_id` NULL = 0; pasangan duplikat = 0. | `evidence/sql/03-stock-quality.png` dengan query dan output lengkap | Hasil dilaporkan; lampiran perlu dicek |
| D4 | Ada 12 merchant, jadwal sinkron 15 menit, digest 07.00 WIB; hasil 188 baris dari 11 merchant pada satu run. Uji beban maksimum belum tersedia. | `evidence/wf1/schedule.png`; `evidence/wf1/sync-execution.png`; `evidence/deploy/07-resource-usage.png` | Cukup untuk skenario terbatas jika bukti lengkap; kapasitas produksi belum diuji |

**Kesimpulan Data:** Data kualitas stok memenuhi nilai yang dilaporkan; kemampuan produksi pada beban puncak belum dibuktikan.

### C. Access & Security Readiness

| ID | Kriteria dan temuan | Bukti yang wajib ditautkan | Status saat revisi |
|---|---|---|---|
| S1 | Rahasia API dan database dikelola melalui n8n Credentials, bukan ditanam di workflow. | `evidence/security/01-credentials-list.png` (nama credential saja, tanpa secret); review export JSON | Perlu lampiran dan audit export |
| S2 | `mcp_reader` untuk MCP SELECT; `ops_writer` untuk PostgreSQL node INSERT/UPDATE/UPSERT/DELETE. | `evidence/sql/04-role-grants.png`; `evidence/security/02-ops-writer-nodes.png` (node tulis + credential yang dipilih) | Perlu bukti konfigurasi akhir |
| S3 | `mcp_reader` dapat SELECT pada tabel yang diizinkan dan **tidak dapat INSERT**. | `evidence/sql/05-mcp-reader-insert-denied.png` (perintah, error permission/read-only, dan tabel sasaran yang valid); hasil `has_table_privilege` bila ada | Perlu lampiran pengujian negatif |
| S4 | Pengembang menyatakan secret tidak dibagikan di repo/chat. Klaim harus diperkuat dengan pemeriksaan repo dan prosedur distribusi token penilai secara privat. | `evidence/security/03-secret-scan.png` (tanpa menampilkan secret); catatan distribusi credential privat/rotasi | Konfirmasi pengembang; belum diaudit independen |

**Kesimpulan Security:** Pemisahan role merupakan rancangan yang tepat, tetapi S2–S4 tidak dapat diberi nilai penuh hanya berdasarkan pernyataan tanpa evidence.

### D. Operational Readiness

| ID | Kriteria dan temuan | Bukti yang wajib ditautkan | Status saat revisi |
|---|---|---|---|
| O1 | Pengembang menjadi PIC selama Milestone; WF5 dan Telegram menjadi jalur notifikasi. PIC produksi dan eskalasi lanjutan belum disahkan. | `evidence/wf5/error-execution.png`; `evidence/wf5/telegram-alert.png`; catatan PIC dan kanal eskalasi | Siap terbatas untuk Milestone; PIC produksi perlu ditetapkan |
| O2 | Jadwal sync 15 menit dan digest 07.00 WIB bukan jadwal maintenance. Jendela maintenance rutin, owner dan pemberitahuan belum tertulis. | `docs/operational-maintenance.md` atau bagian prosedur operasional yang mencantumkan jadwal, PIC, pause/resume, komunikasi | Perlu tindakan |
| O3 | EC2 `t3.small`, Uptime Kuma tersedia. Belum ada bukti pengujian kapasitas puncak, penggunaan RAM/CPU dan batas operasional. | `evidence/deploy/02-compose-ps.png`; `evidence/deploy/07-resource-usage.png`; `evidence/wf5/uptime-kuma.png` | Monitoring tersedia; kapasitas produksi belum diuji |
| O4 | Rollback workflow direncanakan melalui export terakhir; backup/restore PostgreSQL dan volume n8n belum terbukti. | `evidence/ops/backup-log.png`; `evidence/ops/restore-test.png`; prosedur rollback tertulis | Perlu tindakan dan uji restore |

**Kesimpulan Operasional:** Lingkungan dapat digunakan untuk demonstrasi setelah smoke test, tetapi belum memiliki bukti yang cukup untuk kesiapan operasional bisnis nyata.

## 3. Bukti uji workflow WF1–WF5

| Workflow | Klaim hasil | Evidence minimum yang harus tersedia | Penilaian saat revisi |
|---|---|---|---|
| WF1A Stock Sync | 11/12 merchant; 188 baris pada run; stok akhir 205; M009 error 500 | Canvas, execution sukses/gagal, `ops.dead_letter`, `/admin/stock-calls`, SQL stok | Dilaporkan; verifikasi lampiran |
| WF1B Order Intake | Status 200/409/422 dan duplikasi | Empat contoh HTTP request/response + query order tidak duplikat | Dilaporkan; verifikasi lampiran |
| WF1C Digest | KPI 7 Nov dan Telegram | Execution, output agregasi, pesan Telegram, kondisi IF yang benar | Dilaporkan; retest IF |
| WF2 MCP | Tiga tool merchant M003 dan read-only | Output ketiga tool; query privilege dan INSERT ditolak | Dilaporkan; verifikasi lampiran |
| WF3 AI Merchant | Jawaban, eskalasi, tiket, Telegram | Output `status` sukses/eskalasi/error, tiket di DB, Telegram, Error Workflow WF5 | Belum lengkap sampai status/error terbukti |
| WF4 Compensation | Voucher `VC-00001`; refund dan approval | Voucher, refund kecil/besar, approve/reject, idempotency key, duplikasi | Bukti skenario lengkap perlu diverifikasi |
| WF5 Error Handling | Alert Telegram dan Notification | Error Trigger dari WF sumber, execution WF5, payload Notification, Telegram | Perlu bukti end-to-end |

## 4. Perintah pemeriksaan SQL untuk evidence

Jalankan pada database `h8mart`; simpan screenshot query **dan hasil**. Jangan masukkan password/token ke evidence.

**Kualitas stok:**

```sql
SELECT COUNT(*) AS total_stok, COUNT(*) FILTER (WHERE product_id IS NULL) AS product_id_null, COUNT(*) - COUNT(DISTINCT (merchant_id, product_id)) AS pasangan_duplikat FROM core.merchant_stock;
```

**Isi dan jumlah dead-letter:**

```sql
SELECT workflow, business_key, error_message FROM ops.dead_letter ORDER BY created_at DESC LIMIT 20;
SELECT COUNT(*) AS total_dead_letter FROM ops.dead_letter;
```

**Hak akses role:**

```sql
SELECT grantee, table_schema, table_name, privilege_type FROM information_schema.role_table_grants WHERE grantee IN ('mcp_reader', 'ops_writer') ORDER BY grantee, table_schema, table_name, privilege_type;
```

**Uji INSERT ditolak:** Jalankan dengan koneksi login `mcp_reader` terhadap tabel dengan struktur dan kolom yang sudah dipastikan valid, dalam transaksi yang di-rollback. Bukti yang sah adalah `permission denied` atau penolakan read-only, **bukan** error kolom/sintaks. Hindari menampilkan password pada command line/screenshot.

## 5. Rekap readiness dan keputusan

| Dimensi | Ringkasan | Kesimpulan |
|---|---|---|
| API (A1–A4) | Endpoint dan error path pernah diuji; evidence terstruktur masih perlu diverifikasi | Belum semua kriteria terbukti |
| Data (D1–D4) | SQL kualitas stok dilaporkan baik; uji kapasitas puncak belum ada | Siap untuk uji terbatas setelah evidence |
| Security (S1–S4) | Credentials dan role tersedia; perlu bukti ops_writer, penolakan INSERT, dan audit secret | Belum semua kriteria terbukti |
| Operational (O1–O4) | Monitoring tersedia; maintenance dan restore belum diuji/disahkan | Belum siap go-live nyata |

**Keputusan Milestone:** **Layak untuk demonstrasi/pengujian terbatas secara bersyarat**, setelah webhook produksi, execution WF1–WF5, field `status` WF3, dan evidence keamanan dapat ditunjukkan kepada instruktur. Ini bukan klaim bahwa seluruh rubrik sudah lulus.

**Keputusan bisnis nyata:** **BELUM ADA PERSETUJUAN GO-LIVE.** Status GO BERSYARAT hanya dapat diusulkan setelah kriteria, mitigasi, pemilik risiko, tanggal review dan penerimaan risiko terdokumentasi. Tidak ada dasar untuk menyatakan skor readiness **8/8** atau skor final lainnya tanpa bukti tiap gate dan aturan penilaian materi.

## 6. Tindak lanjut dan penanggung jawab

| Prioritas | Temuan | Tindakan | PIC sementara | Bukti selesai |
|---|---|---|---|---|
| Tinggi | WF3 belum dibuktikan mengirim `status` pada semua jalur | Uji sukses, eskalasi, dan error; aktifkan Error Workflow WF5 | Pengembang | `evidence/wf3/response-status.png`, executions |
| Tinggi | Bukti SQL keamanan dan error belum tertaut | Simpan hasil `ops.dead_letter`, role grants, dan INSERT ditolak | Pengembang | `evidence/sql/` |
| Tinggi | Endpoint retry belum didokumentasikan | Lampirkan hasil `/admin/stock-calls` beserta waktu uji | Pengembang | `evidence/wf1/stock-calls.png` |
| Tinggi | Evidence deployment belum terstruktur | HTTPS, `docker compose ps`, webhook eksternal, Telegram | Pengembang | `evidence/deploy/` dan `evidence/wf*/` |
| Sedang | Maintenance belum ditetapkan | Buat jadwal, owner, prosedur pause/resume dan komunikasi | Pengembang / calon Ops | Dokumen maintenance |
| Tinggi sebelum produksi | Restore DB belum diuji | Backup dan uji restore pada lingkungan terisolasi | Pengembang / DBA | Log restore dan verifikasi data |
| Sedang | Kapasitas belum diukur | `docker stats`, penggunaan memori, uji beban terkontrol | Pengembang | Screenshot dan catatan batas |
| Tinggi sebelum produksi | Risiko dan PIC belum disahkan | Tunjuk owner, tanggal review, keputusan GO/NO-GO | Pemilik proses (belum ditetapkan) | Persetujuan tertulis |

## 7. Struktur evidence yang direkomendasikan

```text
evidence/
├── deploy/
│   ├── 01-ec2-running.png
│   ├── 02-compose-ps.png
│   ├── 03-https-valid.png
│   ├── 04-production-webhook.png
│   └── 07-resource-usage.png
├── sql/
│   ├── 01-schema.png
│   ├── 02-columns.png
│   ├── 03-stock-quality.png
│   ├── 04-role-grants.png
│   └── 05-mcp-reader-insert-denied.png
├── security/
├── ops/
├── wf1/
├── wf2/
├── wf3/
├── wf4/
└── wf5/
```

Struktur di atas bersifat usulan. Ikuti nama file dan bukti minimum dalam `guide/submission.md` jika berbeda. Jangan commit `.env`, API key, token Telegram, password, maupun nilai credential. Screenshot harus disensor bila mengandung informasi rahasia.

## 8. Batasan asesmen

Dokumen ini menyatakan temuan yang dilaporkan pengguna dan daftar bukti yang perlu ditautkan. Penilaian akhir memerlukan pemeriksaan file evidence aktual dan eksekusi terbaru. Data H8Mart masih sintetis; kesiapan demo tidak setara dengan kesiapan layanan bisnis nyata.

**Referensi internal:** `README.md`, `data-contract.md`, `guide/submission.md`, `docs/02-desain-solusi-roi.md`, `docs/03-tco-deployment.md`, export `workflows/`, dan folder `evidence/`.
