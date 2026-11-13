# 04. Integration Readiness & System Compatibility — H8Mart

**Tanggal pemeriksaan:** 13 November 2026  
**Lingkungan:** AWS EC2 (Ubuntu 24.04), Docker Compose, n8n, PostgreSQL, Mock API, Caddy, dan Uptime Kuma  
**Ruang lingkup:** integrasi Merchant Stock API, Order Intake, MCP, AI Merchant Assistant, Compensation/Refund, dan monitoring.

## 1. Hasil pemeriksaan

Pemeriksaan ini dilakukan setelah workflow H8Mart diuji di server. WF1 sampai WF5 telah dijalankan dan hasil pengujiannya sesuai skenario yang dicoba. Pemeriksaan readiness digunakan untuk melihat kesiapan API, database, akses, serta operasional. Status pengujian workflow dan kesiapan go-live dinilai secara terpisah.

### A. API Readiness

| Kode | Item | Kondisi yang ditemukan | Status |
| --- | --- | --- | --- |
| A1 | Dokumentasi dan pengujian endpoint | API H8Mart memiliki kontrak pengujian. Endpoint Merchant Stock dan Notification sudah dipanggil dari workflow. | Siap |
| A2 | Ketersediaan endpoint | Endpoint yang digunakan oleh WF1–WF4 dapat diakses pada skenario pengujian yang dilakukan, termasuk webhook produksi. | Siap pada skenario uji |
| A3 | Kesesuaian response | Respons Merchant Stock memiliki `merchant_id`, `as_of`, dan `items`; Notification mengembalikan data pesan. Respons MCP/AI mengikuti struktur yang digunakan pada workflow. | Siap pada skenario uji |
| A4 | Penanganan kode error | M009 mengembalikan HTTP 500 sesuai skenario mock. Retry, pencatatan dead-letter, dan pemberitahuan kegagalan digunakan agar proses merchant lain tetap berjalan. Jalur order 200/409/422 juga telah diuji. | Siap |

**Hasil API:** Siap untuk pengujian dan demonstrasi Milestone. Error M009 merupakan bagian dari skenario penanganan kegagalan, bukan kegagalan seluruh workflow.

### B. Data & Database Readiness

| Kode | Item | Kondisi yang ditemukan | Status |
| --- | --- | --- | --- |
| D1 | Struktur database | Database menggunakan skema `core` dan `ops`. Query PostgreSQL telah digunakan dalam proses stock sync, MCP, dead-letter, dan tiket. | Siap pada tabel yang dipakai |
| D2 | Ketersediaan kolom | Kolom yang digunakan untuk sinkronisasi stok, pembacaan KPI, dan pencatatan operasional dapat diakses pada pengujian. | Siap |
| D3 | Kualitas data | Hasil query `core.merchant_stock`: **205 baris**, **0 `product_id` NULL**, dan **0 duplikasi pasangan (`merchant_id`, `product_id`)**. | Siap — terbukti |
| D4 | Volume dan pola akses | Terdapat 12 merchant. Sinkronisasi dijadwalkan setiap 15 menit dan digest setiap 07.00 WIB. Hasil normalisasi pernah menghasilkan 188 baris untuk 11 merchant yang merespons. Uji beban maksimum belum dilakukan. | Siap untuk beban uji Milestone |

**Hasil Data & Database:** Siap untuk skenario Milestone. Query D3 menunjukkan jumlah dan kualitas data stok sesuai target.

### C. Access & Security Readiness

| Kode | Item | Kondisi yang ditemukan | Status |
| --- | --- | --- | --- |
| S1 | Penyimpanan credential | OpenAI, PostgreSQL, Bearer Auth, Header Auth Mock API, Webhook Auth, dan Telegram disimpan melalui menu **Credentials** pada n8n; terlihat pada screenshot konfigurasi. | Siap — ada bukti |
| S2 | Akun database khusus | MCP memakai role `mcp_reader` dan proses operasional menggunakan credential database tersendiri. | Siap |
| S3 | Pembatasan hak akses | Pengujian pada `mcp_reader` untuk `core.orders` menunjukkan SELECT diperbolehkan, sedangkan INSERT, UPDATE, dan DELETE tidak diperbolehkan. Pemeriksaan ini membuktikan pembatasan pada role dan tabel tersebut. | Siap pada akses yang diuji |
| S4 | Distribusi credential | Selama pengerjaan, API key dan token asli tidak diunggah ke GitHub maupun dibagikan melalui chat, berdasarkan konfirmasi pengembang. | Siap — konfirmasi pengembang |

**Hasil Access & Security:** Penyimpanan credential sudah memakai fasilitas n8n. Pemeriksaan tambahan yang dapat dilakukan sebelum pemakaian bisnis nyata adalah meninjau ulang seluruh hak akses per tabel dan memastikan export workflow tidak menyertakan nilai rahasia.

### D. Operational Readiness

| Kode | Item | Kondisi yang ditemukan | Status |
| --- | --- | --- | --- |
| O1 | PIC dan eskalasi | Selama Milestone, pengoperasian EC2, n8n, dan workflow ditangani oleh pengembang. Error Workflow dan Telegram digunakan untuk notifikasi gangguan. | Siap untuk Milestone |
| O2 | Jadwal maintenance | Jadwal sinkronisasi 15 menit dan digest 07.00 WIB telah diketahui. Maintenance server direncanakan dilakukan di luar jadwal digest dengan trigger terkait dinonaktifkan sementara. Jadwal maintenance rutin belum ditetapkan tertulis. | Perlu penetapan jadwal operasional |
| O3 | Kapasitas dan monitoring | Sistem berjalan pada EC2 `t3.small`; Uptime Kuma digunakan untuk pemantauan. Hasil uji workflow tersedia, sedangkan batas kapasitas maksimum belum diukur. | Siap untuk beban uji Milestone |
| O4 | Rencana rollback | Jika perubahan workflow mengganggu layanan, nonaktifkan trigger terkait, kembalikan workflow dari export versi terakhir yang berhasil, uji kembali, lalu aktifkan/publish ulang. Untuk perubahan Compose/DB, gunakan konfigurasi dan backup yang telah diverifikasi sebelum melakukan perubahan. | Rencana tersedia; pemulihan DB belum diuji |

**Hasil Operasional:** Workflow sudah berjalan dan notifikasi teruji. Sebelum go-live bisnis nyata, jadwal maintenance rutin, penanggung jawab lanjutan, dan pengujian prosedur pemulihan perlu ditetapkan.

## 2. Bukti pengujian workflow

| Workflow | Bukti hasil pengujian | Hasil |
| --- | --- | --- |
| WF1A — Sinkronisasi stok | 11 merchant berhasil diproses; M009 mengalami HTTP 500 yang memang disengaja dan diarahkan ke dead-letter/notifikasi. Data stok akhir berjumlah 205 tanpa `product_id` kosong atau pasangan duplikat. | Lulus |
| WF1B — Order Intake | Skenario respons 200, 409, 422, dan duplikasi order telah diuji. | Lulus |
| WF1C — Daily Digest | Telegram menerima laporan pukul 07.00 WIB. Data 7 November 2026: 162 order, 25 batal, 134 terkirim, 111 tepat waktu; cancel rate 15,43% dan SLA 30 menit 82,84%. | Lulus |
| WF2 — MCP Server | Tool KPI, alasan pembatalan, dan status stok merchant menghasilkan data; role pembaca dibatasi untuk operasi baca pada tabel yang diuji. | Lulus |
| WF3 — AI Merchant Assistant | Bot Telegram menjawab pertanyaan tentang SKU dan menampilkan respons eskalasi untuk pertanyaan voucher/refund yang tidak dapat dilayani langsung. | Lulus pada skenario uji |
| WF4 — Compensation & Refund | Pengujian voucher, refund, dan alur persetujuan telah dilakukan menurut catatan pengujian proyek. | Lulus berdasarkan pengujian |
| WF5 — Error Handling | Error workflow menghasilkan notifikasi Telegram; Notification API juga menerima pesan alert. | Lulus |

*Catatan:* Data digest menggunakan tanggal data terakhir pada dataset uji, sehingga tanggal data pada pesan tidak harus sama dengan tanggal pengiriman Telegram.

## 3. Ringkasan kesiapan

| Dimensi | Hasil pemeriksaan |
| --- | --- |
| API | Siap untuk skenario uji |
| Data & Database | Siap; kualitas data stok terbukti melalui SQL |
| Access & Security | Siap pada konfigurasi dan hak akses yang telah diuji |
| Operational | Siap untuk demonstrasi; dokumentasi maintenance dan uji rollback perlu dilengkapi sebelum operasional bisnis nyata |

**Keputusan untuk Milestone:** **SIAP UNTUK DEMONSTRASI/PENGUJIAN.** WF1–WF5 sudah dijalankan dan fungsi utama yang diperlukan dapat ditunjukkan.

**Keputusan untuk go-live bisnis nyata:** **GO BERSYARAT sebagai usulan asesmen**, bukan persetujuan operasional. Syaratnya adalah jadwal maintenance tertulis, verifikasi backup/restore, dan peninjauan hak akses operasional sebelum digunakan oleh pengguna bisnis. Keputusan akhir memerlukan penerimaan risiko oleh pemilik proses. Skor 0–8 final tidak dinyatakan karena persetujuan dan pemeriksaan operasional tersebut belum menjadi bagian pengujian Milestone.

## 4. Catatan tindak lanjut

| Temuan | Tindak lanjut | Penanggung jawab |
| --- | --- | --- |
| Jadwal maintenance rutin belum tertulis | Tentukan jendela maintenance dan mekanisme pause/resume Schedule Trigger. | Pengembang / pengelola server |
| Pemulihan database belum dibuktikan | Simpan backup dan uji prosedur restore pada lingkungan aman sebelum go-live nyata. | Pengembang / pengelola database |
| Cakupan pengujian hak akses masih terbatas | Periksa privilege role operasional pada seluruh tabel yang digunakan. | Pengembang |
| Bukti pelaksanaan tersebar di screenshot dan Executions | Simpan screenshot final di `evidence/wf1`–`wf5` dan `evidence/deploy`, tanpa nilai secret. | Pengembang |

## 5. Batas bukti

Pemeriksaan melalui SQL dan execution n8n dapat menunjukkan hasil proses, kualitas data, status endpoint, dan sebagian hak akses. Hal yang tidak dapat dibuktikan hanya dari output tersebut ialah cara credential pernah dibagikan, penetapan PIC ketika sistem diserahkan, jadwal maintenance yang disepakati, serta kesiapan prosedur pemulihan. Untuk Milestone, informasi ini dicatat sesuai kondisi proyek; untuk penggunaan bisnis nyata, perlu konfirmasi dan dokumentasi operasional.

**Lampiran bukti yang digunakan:** hasil query kualitas data stok; halaman Credentials n8n; screenshot Telegram AI Merchant Assistant; screenshot Telegram Daily Ops Digest; serta hasil pengujian workflow yang tersimpan pada Executions/evidence proyek.
