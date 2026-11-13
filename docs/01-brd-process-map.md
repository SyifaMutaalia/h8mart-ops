# 01 · Business Requirement Document (BRD) dan Pemetaan Proses Bisnis H8Mart

**Proyek:** H8Mart Quick-Commerce Operations · Milestone 3 Phase 3\
**Tanggal pembaruan:** 13 November 2026

## 1. Business Requirement Document (BRD)

| Item                                                 | Isi                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | Sumber / status bukti                                                                   |
| :--------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------- |
| **Masalah bisnis**                                   | Stok merchant perlu pembaruan berkala; order berisiko diterima saat stok tidak cukup; laporan cancel rate/SLA disusun dari data yang tersebar; voucher/refund harus konsisten dan tidak dibayar berulang; pertanyaan merchant dan kegagalan automasi membutuhkan jalur penanganan.                                                                                                                                                                                                                                                                               | `README.md` §Skenario, `guide/wf1...` s.d. `guide/wf5...` (skenario proyek).            |
| **Tujuan & ukuran keberhasilan**                     | (a) Sinkron 12 merchant setiap 15 menit, gagal per merchant tidak menghentikan merchant lain; (b) stok memiliki `product_id` benar dan relasi seed **205** tetap tidak bertambah setelah sinkron ulang; (c) order valid diterima HTTP **200**, stok kurang HTTP **409**, input tidak valid HTTP **422**; (d) digest **07.00 WIB**, KPI cocok SQL independen; (e) jawaban merchant memiliki sumber tool dan eskalasi jika tidak memadai; (f) voucher/refund idempoten dan refund tertentu memerlukan approval; (g) alert error berisi workflow/node/business key. | Kriteria di `guide/submission.md`; target rancangan dan hasil pengujian pada folder `evidence/`. |
| **Stakeholder & aktor**                              | Pelanggan, merchant, Ops, CS, reviewer/approver Ops, tim teknis; sistem eksternal: Merchant Stock API, Payment API, Notification API, Telegram, OpenAI API, PostgreSQL.                                                                                                                                                                                                                                                                                                                                                                                          | `README.md`, `data-contract.md`, diagram workflow.                                      |
| **Volume & frekuensi**                               | **12 merchant**, jadwal stok **15 menit** (96 kali/hari bila terus aktif), digest **1 kali/hari**, relasi stok seed **205**, hasil normalisasi saat pengujian **188 baris**. Jumlah order per bulan dan biaya waktu operasional **belum terukur**; asumsi ada di ROI/TCO.                                                                                                                                                                                                                                                                                | `guide/wf1...`, `data-contract.md`, hasil uji WF1A.                                     |
| **Aturan bisnis BR1 — Stok & order**                 | Event `order.created` harus valid; stok tidak boleh kurang dari permintaan; nominal order harus sesuai kontrak; satu `order_id` tidak boleh dicatat ganda. Pilih **200 / 409 / 422** berdasarkan validasi.                                                                                                                                                                                                                                                                                                                                                       | `data-contract.md`, `guide/wf1-stock-sync-order-intake.md`.                             |
| **Aturan bisnis BR2 — Kompensasi**                   | Event `delivery.late` atau `order.failed` diproses lewat kebijakan deterministik WF4. Voucher yang memenuhi syarat otomatis; refund besar masuk **approval Ops**; gunakan `Idempotency-Key` ketika memanggil Payment API. Nilai ambang mengikuti aturan yang dikonfigurasi pada workflow WF4.                                                                                                                                                                                                                   | `guide/wf4-compensation-refund.md`.                                                     |
| **Aturan bisnis BR3 — Keandalan & layanan merchant** | Merchant API yang gagal dicoba ulang; kegagalan tetap dicatat di `ops.dead_letter` dan `/notify`. MCP WF2 menggunakan akses read-only. WF3 hanya menjawab sesuai data tool, dan mengeskalasi ketika guardrail gagal. Kegagalan workflow dipantau oleh WF5.                                                                                                                                                                                                                                                                                                       | `guide/wf2...`, `guide/wf3...`, `guide/wf5...`, hasil pengujian workflow.                      |
| **Dalam scope automasi**                             | WF1A sinkron stok, WF1B penerimaan order, WF1C digest; WF2 MCP tiga tool; WF3 AI Merchant + jalur Telegram/allowlist; WF4 kompensasi dan refund; WF5 error handler, Telegram alert, Notification API, dan monitoring.                                                                                                                                                                                                                                                                                                                                            | `guide/tasks.md`, diagram aset H8Mart, implementasi workflow H8Mart.                            |
| **Di luar scope**                                    | Pembayaran produksi yang memakai uang nyata; data pelanggan sungguhan; keputusan refund berisiko tanpa persetujuan manusia; klaim AI mengenai detail order yang tidak disediakan MCP; analisis transaksi uang nyata di luar lingkungan simulasi.                                                                                                                                                                                                                                                                                                                       | Pembatasan skenario mock dan prinsip risk governance.                                   |

**Hasil implementasi:** WF1–WF5 telah dibuat dan diuji. Sinkronisasi stok menghasilkan 188 baris normalisasi pada satu eksekusi; pemeriksaan database menunjukkan 205 baris di `core.merchant_stock`, tidak ada `product_id` NULL, dan tidak ada duplikasi pasangan `(merchant_id, product_id)`. Pengujian penerimaan order mencakup HTTP 200, 409, dan 422. Laporan operasional harian telah terkirim melalui Telegram pukul 07.00 WIB dengan data 162 order, 25 pembatalan, 134 order terkirim, dan 111 tepat waktu. Ketiga tool MCP, AI Merchant Assistant, penanganan kompensasi/refund, dan notifikasi kesalahan juga telah diuji. Bukti pendukung disimpan pada folder `evidence/` sesuai workflow.

## 2. Process Map As-Is

**Objek yang dipetakan:** proses penerimaan order, pemeriksaan stok, pemantauan pengiriman, dan penanganan kompensasi. Alur As-Is menggambarkan proses manual sebagai pembanding terhadap otomatisasi H8Mart berdasarkan skenario proyek.

[Process Map As-Is H8Mart](../assets/process-map-as-is.png)

**Diagram dapat diedit melalui Draw.io atau Miro:** [`process-map-as-is.drawio`](../assets/process-map-as-is.drawio). Kedua peta memakai **kode elemen yang sama**. Oval = event, kotak = aktivitas, belah ketupat = gateway keputusan, oranye = aktivitas manusia, merah = exception.

**Pembacaan gateway:** `D1` Stok cukup? (Ya/Tidak), `D2` Terlambat/gagal? (Ya/Tidak), `D3` Perlu approval? (Ya/Tidak). `E1` tetap menuju pemberitahuan/penutupan, bukan berhenti tanpa hasil. `H1` adalah titik keputusan manusia. Jika `D2` bernilai **Tidak**, proses menuju `P6` (selesai tanpa kompensasi); jika approval ditolak, dicatat pada `E2`. Panah putus-putus `P2 → P3` menandakan **event berikutnya pada eksekusi berbeda**, bukan proses synchronous.

## 3. Elemen Process Map As-Is

| Kode  | Elemen As-Is                           | Notasi            | Aktor         | Makna                                             |
| :---- | :------------------------------------- | :---------------- | :------------ | :------------------------------------------------ |
| START | Pesanan/keluhan masuk                  | Start event       | Pelanggan     | Proses dimulai dari kejadian bisnis.              |
| P0    | Pelanggan menyampaikan order           | Task              | Pelanggan     | Menyertakan identitas dan isi order.              |
| P1    | CS mengecek stok ke merchant           | Task manual       | Ops/CS        | Menghindari memproses order tanpa stok.           |
| D1    | Stok cukup?                            | Exclusive gateway | Ops/CS        | Ya melanjutkan proses, Tidak ke E1.               |
| E1    | Konfirmasi stok / tolak order          | Exception task    | Ops/CS        | Pemberitahuan jika stok/validasi tidak memadai.   |
| P2    | CS mencatat dan memproses order        | Task manual       | Ops/CS        | Pencatatan order dan penerimaan.                  |
| P3    | CS memantau status pengiriman          | Task manual       | Ops/CS        | Menentukan perlu tidaknya tindakan lanjutan.      |
| D2    | Ada keterlambatan/order gagal?         | Exclusive gateway | Ops/CS        | Tidak → catat/beri info; Ya → kaji kompensasi.    |
| P4    | CS menghitung voucher/refund           | Task manual       | Ops/CS        | Menilai nilai kompensasi menurut kebijakan.       |
| D3    | Perlu approval?                        | Exclusive gateway | Ops/CS        | Ya → H1; Tidak → tindakan sesuai kebijakan.       |
| H1    | Ops menyetujui atau menolak            | Human task        | Approver Ops  | Keputusan finansial tetap manusia.                |
| P5    | Log hasil dan pemberitahuan kompensasi | Task manual       | Ops/CS        | Jejak keputusan dan pesan kepada pihak terkait.   |
| P6    | Tutup pesanan tanpa kompensasi         | Task manual       | Ops/CS        | Cabang status normal tidak memanggil Payment API. |
| E2    | Catat penolakan approval               | Exception task    | Ops/CS        | Penolakan Ops tercatat tanpa pembayaran.          |
| END   | Proses ditutup                         | End event         | Pelanggan/Ops | Hasil permintaan tercatat/disampaikan.            |

## 4. Translasi Proses Bisnis ke Workflow n8n

| Kode  | Langkah manual As-Is                   | Elemen otomasi                                | Nama node To-Be / WF                                                                                                                | **Alasan pemilihan**                                                                                                                                                            |
| :---- | :------------------------------------- | :-------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| START | Permintaan masuk via komunikasi manual | Start Event                                   | `Webhook order.created` (WF1B)                                                                                                      | Event formal mengurangi penyalinan pesan manual.                                                                                                                                |
| P0    | Pelanggan menyampaikan order           | Webhook + Header Auth                         | `Webhook Order Created` / node intake WF1B                                                                                          | Payload terstruktur diperlukan untuk validasi deterministik dan pengujian HTTP.                                                                                                 |
| P1    | CS mencocokkan stok                    | Schedule, HTTP Request, Code, Merge, Postgres | `Loop per Merchant`, `Normalisasi Stok`, `Ada Baris Stok?`, `Gabungkan Katalog`, `Upsert Stok` (WF1A), lalu `Cek Stok Order` (WF1B) | Sinkron berkala memelihara sumber stok; cek stok saat order tetap diperlukan agar tidak memakai asumsi. **WF1A dan WF1B punya trigger berbeda**, bukan satu eksekusi berurutan. |
| D1    | CS menentukan stok cukup atau tidak    | IF + Switch + SQL                             | `Event Valid?`, `Cek Stok Order`, `Routing Stok` (WF1B)                                                                             | Aturan stok/nominal bersifat numerik dan dapat dievaluasi tanpa AI.                                                                                                             |
| E1    | CS menolak/konfirmasi bila gagal       | Respond to Webhook + log                      | `Respon 409 Stok Habis`, `Respon 422 Tidak Valid` (WF1B)                                                                            | Jalur exception harus memiliki respons HTTP yang jelas; jalur validasi serta order duplikat ditangani sesuai respons yang ditetapkan.                                                      |
| P2    | CS mencatat order                      | PostgreSQL + Respond                          | `Catat Order`, `Respon 200 Diterima` (WF1B)                                                                                         | Status order perlu persisted, dan `order_id` harus idempoten.                                                                                                                   |
| P3    | CS memantau pengiriman                 | Webhook event                                 | `Terima Event` (WF4)                                                                                                                | Status terlambat/gagal dapat menjadi event terstruktur; **WF1C Digest** berjalan pada jadwalnya sendiri, bukan kelanjutan satu order.                                           |
| D2    | CS memeriksa keterlambatan/gagal       | Switch                                        | `Jenis Event?` (WF4)                                                                                                                | Event menentukan kebijakan voucher vs refund.                                                                                                                                   |
| P4    | CS memperkirakan kompensasi            | SQL + Edit Fields/Code                        | `Ambil Order`, `Tentukan Kebijakan` (WF4)                                                                                           | Nominal dan ambang perlu eksplisit serta dapat diaudit.                                                                                                                         |
| D3    | CS mengecek perlu approval             | IF                                            | `Perlu Approval?` (WF4)                                                                                                             | Aktivitas finansial berisiko tinggi perlu dibedakan dari transaksi otomatis.                                                                                                    |
| H1    | Approver Ops memutuskan                | Telegram Send and Wait / Wait                 | `Minta Approval Telegram`, `Disetujui?` (WF4)                                                                                       | Hanya manusia berwenang boleh menyetujui refund besar; penolakan tidak boleh memanggil Payment API.                                                                             |
| P5    | CS mencatat hasil & mengabari          | HTTP Request + PostgreSQL                     | `Panggil Payment Voucher/Refund`, `Catat Refund Selesai`, `Notifikasi ...` (WF4)                                                    | `Idempotency-Key`, log dan pesan memberikan jejak transaksi.                                                                                                                    |
| P6    | Tutup order normal tanpa kompensasi    | Log/Notification                              | Catat status selesai, tanpa Payment API                                                                                             | Status pengiriman normal tidak boleh menimbulkan transaksi finansial.                                                                                                           |
| E2    | Penolakan keputusan finansial          | IF + PostgreSQL                               | `Tandai Ditolak` / catat keputusan WF4                                                                                              | Penolakan tidak memanggil Payment API dan tetap meninggalkan jejak.                                                                                                             |
| END   | Pelanggan menerima hasil               | End event                                     | HTTP response / Notification API                                                                                                    | Proses harus memiliki hasil terminal yang dapat diaudit.                                                                                                                        |

**Workflow pendukung** (memiliki pemicu dan waktu eksekusi masing-masing):

| Kode dukungan | Proses bisnis           | Padanan node aktual                                                                                                   | Kapan dieksekusi                                                                               |
| :------------ | :---------------------- | :-------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------- |
| S1            | Sinkron stok merchant   | WF1A: Schedule → HTTP Retry → Loop → Normalisasi → Upsert → heartbeat, dead-letter `/notify` bila gagal               | Terjadwal setiap 15 menit jika trigger aktif.                                                  |
| S2            | Laporan Ops harian      | WF1C: `Hitung KPI Harian` → `Digest Kosong?` → MCP WF2 → Telegram/Notification                                        | Terjadwal 07.00 WIB jika trigger aktif.                                                        |
| S3            | Membaca KPI/alasan/stok | WF2: `MCP Server Trigger` dengan tiga PostgreSQL tools dan `mcp_reader`                                               | Saat dipanggil oleh MCP Client (WF3, atau WF1C).                                               |
| S4            | Pertanyaan merchant     | WF3: Webhook/Telegram → allowlist → Agent + WF2 MCP → `Lolos Guardrail?` → jawaban atau `ops.tickets`                 | Saat merchant bertanya; Telegram menghubungi endpoint WF3 dan dapat memulai eksekusi terpisah. |
| S5            | Deteksi kegagalan       | WF5: Error Trigger → pesan Telegram → Notification API; WF1 juga punya gate sinkron 0 baris, keterlambatan, heartbeat | Saat terjadi error atau kondisi pemantauan terpenuhi.                                          |

**Aturan pengambilan keputusan berbasis kondisi:** `Event Valid?` / `Routing Stok` (WF1B), `Digest Kosong?` (WF1C), `Lolos Guardrail?` (WF3), dan **`Tentukan Kebijakan` / `Perlu Approval?` (WF4)**. AI tidak menentukan sendiri besar refund.

## 5. Aktivitas yang Tetap Memerlukan Penanganan Manusia

| Kode  | Langkah manual                                                    | Alasan tetap manual                                                                          | Bentuk dalam automation flow                                                                                          |
| :---- | :---------------------------------------------------------------- | :------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------- |
| H1    | Approval refund besar oleh Ops                                    | Menyangkut otorisasi keputusan finansial; tidak layak diputuskan sepenuhnya oleh AI/otomasi. | WF4 `Minta Approval Telegram` (Send and Wait), `Disetujui?`, penolakan dicatat, Payment tidak dipanggil jika ditolak. |
| S4-CS | Menangani tiket merchant yang tidak dapat dijawab dengan data MCP | Akses dan kebijakan layanan terbatas; AI harus mengakui batasannya.                          | WF3 `Buat Tiket CS` → penanganan oleh petugas CS.                                                                     |

## 6. Process Map To-Be

[Process Map To-Be H8Mart](../assets/process-map-to-be.png)

**Diagram yang dapat diedit:** [`process-map-to-be.drawio`](../assets/process-map-to-be.drawio). Node mempertahankan kode As-Is yang sama di awal label, misalnya `P4 · WF4 Tentukan Kebijakan`. `P6` adalah jalur normal tanpa kompensasi, dan `E2` mencatat approval ditolak. Alur To-Be utama berfokus pada **order dan kompensasi**. Workflow asinkron lain tercatat terpisah pada tabel S1–S5, untuk memperjelas keterkaitan proses.

| Kode         | Perubahan dari As-Is ke To-Be                                                      | Alasan                                                                            |
| :----------- | :--------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------- |
| P0           | Pesan bebas → `Webhook order.created` terstruktur                                  | Payload dapat divalidasi dan dijawab dengan kode HTTP yang terukur.               |
| P1 + D1      | Cek stok manual → sinkron terjadwal + SQL + IF/Switch                              | Mengurangi keterlambatan status stok dan memastikan keputusan stok deterministik. |
| E1           | Penolakan via chat → respons HTTP 409/422 + log                                    | Klien mendapatkan respons jelas; exception tidak diam-diam berhenti.              |
| P2           | Catatan manual → `Catat Order` idempoten                                           | Menghindari data order ganda pada pengiriman ulang.                               |
| P3 + D2 + P4 | Pantau pengiriman dan hitung kompensasi manual → webhook event + aturan WF4        | Tindakan berdasar status nyata serta ambang terdokumentasi.                       |
| H1           | Persetujuan manusia **tetap** diperlukan                                           | Batas tanggung jawab finansial tidak berpindah ke AI.                             |
| P5           | Catat dan kirim pemberitahuan manual → Payment API + PostgreSQL + Notification API | Jejak audit dan idempotensi dapat diuji.                                          |
| P6           | Proses normal → tutup tanpa kompensasi                                             | Tidak memicu Payment API jika tidak ada keluhan delivery.                         |
| E2           | Persetujuan ditolak → catat status rejected                                        | Tidak ada pembayaran saat manusia menolak.                                        |

## 7. Validasi dan Evaluasi Implementasi

### 7.1 Hasil pengujian workflow

Pengujian dilakukan terhadap masing-masing workflow dan jalur integrasinya. Rangkuman hasil pengujian sebagai berikut.

| Workflow | Pengujian yang dilakukan | Hasil |
| :--- | :--- | :--- |
| WF1A – Sinkronisasi Stok | Sinkronisasi 12 merchant, retry saat API gagal, pencatatan dead-letter, normalisasi dan upsert stok | **Berhasil.** M009 mengalami HTTP 500 sesuai skenario mock dan ditangani melalui retry serta dead-letter. Data akhir berjumlah 205 baris, tanpa `product_id` kosong atau pasangan duplikat. |
| WF1B – Order Intake | Validasi payload, pengecekan stok, respons HTTP 200/409/422, dan pencegahan order ganda | **Berhasil** pada skenario pengujian. |
| WF1C – Daily Ops Digest | Perhitungan KPI, pengambilan alasan pembatalan, pengiriman Telegram sesuai jadwal | **Berhasil.** Pesan diterima pukul 07.00 WIB; dataset laporan bertanggal 7 November 2026. |
| WF2 – MCP Tools | Permintaan KPI merchant, alasan pembatalan, status stok, dan pembatasan akses baca | **Berhasil.** Tool mengembalikan data merchant M003; akses `mcp_reader` ke `core.orders` dibatasi untuk SELECT. |
| WF3 – AI Merchant Assistant | Pertanyaan merchant via Telegram, pemanggilan MCP, pembatasan akses dan eskalasi CS | **Berhasil.** Bot menjawab pertanyaan SKU dan mengarahkan permintaan di luar dukungan tool ke CS. |
| WF4 – Kompensasi dan Refund | Proses voucher, refund, persetujuan Ops dan penggunaan idempotency key | **Berhasil** berdasarkan pengujian skenario WF4; voucher `VC-00001` dihasilkan saat pengujian. |
| WF5 – Error Handler | Penanganan kegagalan workflow dan pengiriman alert | **Berhasil.** Notifikasi kesalahan dikirim ke Telegram dan Notification API pada pengujian error. |

Output normalisasi **188 baris** menunjukkan data yang diproses dalam salah satu eksekusi sinkronisasi, sedangkan **205 baris** merupakan total data akhir yang diperiksa di tabel `core.merchant_stock`. Kedua angka memiliki konteks pengukuran yang berbeda.

### 7.2 Pengecekan kesesuaian proses

| Aspek | Hasil implementasi | Keterangan |
| :--- | :--- | :--- |
| Pemeriksaan stok | Menggunakan sinkronisasi terjadwal dan pengecekan stok saat order diterima | Pemeriksaan stok tidak hanya mengandalkan jawaban AI. |
| Merchant API bermasalah | Retry, dead-letter, dan notifikasi diterapkan pada merchant yang gagal | Kegagalan M009 merupakan bagian dari skenario uji. |
| Pelaporan operasional | Daily Digest menghasilkan ringkasan KPI dan alasan pembatalan | Telegram menerima laporan otomatis pada pukul 07.00 WIB. |
| Pertanyaan merchant | AI menggunakan data MCP dan memiliki jalur eskalasi | Pertanyaan yang tidak dapat dijawab berdasarkan tool diarahkan ke CS. |
| Kompensasi finansial | Aturan voucher/refund dipisahkan dari keputusan persetujuan Ops | Pengeluaran refund yang memerlukan persetujuan tidak diputuskan oleh AI. |
| Monitoring | Alert dikirim melalui Telegram dan Notification API | Jalur error handling dapat ditelusuri melalui eksekusi n8n. |

### 7.3 Batasan dan tindak lanjut operasional

Sistem H8Mart pada milestone ini menggunakan data dan layanan simulasi. Pengujian dilakukan untuk memeriksa integrasi antarworkflow, ketepatan alur bisnis, penanganan kondisi gagal, dan keamanan akses dasar. Penggunaan untuk transaksi bisnis nyata memerlukan penetapan aturan operasional, penanggung jawab insiden, kebijakan pemeliharaan, serta prosedur rollback.

| Bagian | Penanganan pada implementasi | Tindak lanjut operasional |
| :--- | :--- | :--- |
| Data dari Merchant API | Retry dibatasi dan hasil kegagalan dicatat | Pantau durasi sinkronisasi dan jumlah kegagalan per merchant. |
| Order dan status stok | Pemeriksaan stok dan idempotensi dilakukan sebelum mencatat order | Pertahankan pengecekan nilai dan duplikasi pada setiap request. |
| AI Merchant Assistant | Jawaban dibatasi oleh data MCP dan guardrail | Evaluasi respons yang memerlukan eskalasi dan risiko instruksi dari data sumber. |
| Credential | Credential API dan database disimpan pada n8n Credentials | Pastikan ekspor workflow dan repository tidak memuat nilai token rahasia. |
| Ketersediaan layanan | Monitoring dan notifikasi error disediakan | Dokumentasikan jadwal maintenance dan langkah rollback sebelum penggunaan produksi. |
| Biaya | Layanan dijalankan di EC2 `t3.small` dan API terkait | Bandingkan estimasi TCO dengan penggunaan aktual saat periode operasional. |

Dokumen terkait: `docs/02-desain-solusi-roi.md`, `docs/03-tco-deployment.md`, `docs/04-readiness-checklist.md`, dan `docs/05-readme-solusi.md`. Bukti pengujian disimpan dalam folder `evidence/`.
