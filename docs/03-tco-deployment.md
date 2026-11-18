# 03 · TCO 12 Bulan + Keputusan Deployment · H8Mart Quick-Commerce Ops

**Nama:** Syifa Mutaalia  
**Tanggal revisi:** 19 November 2026  
**Cakupan:** Milestone 3, lima workflow n8n (WF1–WF5)  
**Satuan:** USD; semua biaya masa depan adalah **simulasi perencanaan**, bukan tagihan atau penawaran vendor.

## Ringkasan keputusan

**Keputusan deployment Milestone:** **self-hosted AWS EC2 + Docker Compose**. Pada skenario laboratorium, TCO 12 bulan termasuk estimasi LLM adalah **USD 1.560,48**, dibanding cloud **USD 8.830,48** dan on-premise **USD 6.080,48**. Pilihan ini sesuai kebutuhan integrasi n8n, PostgreSQL, Mock API, Caddy, Uptime Kuma, dan pengujian role database. **Keputusan ini bukan persetujuan GO untuk bisnis nyata**; keputusan readiness operasional mengikuti `docs/04-readiness-checklist.md` dan bukti aktual.

## 1. Ruang lingkup dan asumsi

Model kapasitas **35.000 eksekusi/bulan** adalah asumsi pembanding, bukan metrik pemakaian n8n: 2.880 sinkronisasi (setiap 15 menit selama 30 hari), 25.000 event order, 5.000 event kompensasi, dan 2.120 interaksi. Data Milestone bersifat sintetis. Untuk konsistensi dengan `docs/02-desain-solusi-roi.md`, biaya LLM memakai skenario **100 pertanyaan/bulan**, sehingga **tidak sama** dengan 2.120 interaksi dalam asumsi kapasitas. Jika seluruh 2.120 interaksi benar-benar memanggil LLM, biaya token perlu dihitung ulang.

Tarif personel simulasi **USD 15/jam**. Biaya awal USD 0 pada model TCO menandakan tidak ada pengeluaran setup yang dimodelkan di tabel dasar; **biaya implementasi awal USD 120** pada ROI dokumen 02 adalah asumsi tambahan yang tidak termasuk TCO dasar. Angka harga infrastruktur, layanan, dan risiko belum diverifikasi sebagai quotation untuk region Jakarta.

## 2. Perbandingan TCO 12 bulan

Rumus: `TCO_12 = 12 × (biaya langsung bulanan + jam admin bulanan × USD 15) + operasional tahunan + cadangan risiko tahunan + biaya LLM tahunan`.

| Komponen | Cloud / SaaS (simulasi) | Self-hosted AWS (simulasi) | On-premise (simulasi) |
|---|---:|---:|---:|
| Biaya layanan/infrastruktur per bulan | 720,00 | 25,00 | 210,00 |
| Admin per bulan (jam) | 0,5 | 4 | 12 |
| Biaya admin per bulan | 7,50 | 60,00 | 180,00 |
| Biaya operasional lain per tahun | 0,00 | 240,00 | 900,00 |
| Cadangan risiko per tahun | 100,00 | 300,00 | 500,00 |
| **TCO dasar 12 bulan** | **8.830,00** | **1.560,00** | **6.080,00** |
| Estimasi LLM 12 bulan | 0,48 | 0,48 | 0,48 |
| **TCO 12 bulan + LLM** | **8.830,48** | **1.560,48** | **6.080,48** |

Verifikasi aritmetika: Cloud `(720 + 0,5×15)×12 + 100 = 8.830`; self-hosted `(25 + 4×15)×12 + 240 + 300 = 1.560`; on-premise `(210 + 12×15)×12 + 900 + 500 = 6.080`. Selisih cloud versus self-hosted **USD 7.270/tahun**; on-premise versus self-hosted **USD 4.520/tahun**. Karena tambahan LLM sama pada ketiga opsi, selisihnya tidak berubah.

**Batas komparabilitas:** USD 720/bulan untuk n8n Enterprise adalah **asumsi latihan, bukan harga resmi**; layanan SaaS, fitur, dan alokasi eksekusinya belum dibuktikan setara dengan self-hosted. Biaya on-premise juga asumsi laboratorium, bukan quotation perangkat. Karena itu, peringkat TCO hanya berlaku untuk skenario ini.

## 3. Rincian biaya AWS self-hosted

### 3.1 Estimasi model Day 3 (bukan tarif terverifikasi Jakarta)

| Komponen | Asumsi | Estimasi bulanan |
|---|---|---:|
| EC2 `t3.small` | USD 0,0264/jam × 730 jam | USD 19,27 |
| EBS gp3 20 GiB | USD 0,096/GiB-bulan × 20 | USD 1,92 |
| IPv4 publik | USD 0,005/jam × 730 jam | USD 3,65 |
| **Subtotal** | | **USD 24,84** |
| **Pembulatan model** | | **USD 25,00** |

Harga EC2 dan EBS tersebut merupakan **parameter latihan**, bukan klaim harga on-demand `ap-southeast-3`. Belum termasuk transfer data keluar, snapshot, pajak, kemungkinan tambahan volume/IP, dan kredit AWS. Jika ada dua instance berjalan, perhitungan untuk satu instance tidak otomatis mencakup keduanya. Cek AWS Pricing Calculator, spesifikasi instance H8Mart, Billing, dan diskon/kredit sebelum mengubahnya menjadi proyeksi riil.

### 3.2 Fakta biaya dari screenshot AWS

Screenshot **AWS EC2 Dashboard** yang disediakan pada 19 November 2026 memperlihatkan:

| Indikator pada layar | Nilai teramati | Interpretasi |
|---|---|---|
| Region dashboard | Asia Pacific (Jakarta), `ap-southeast-3` | Region yang sedang dipilih pada dashboard |
| Instances (running) | 2 | Jumlah seluruh instance running dalam tampilan akun/region; belum diatribusikan per proyek |
| Instances (total) | 2 | Jumlah instance pada dashboard |
| Volumes | 2 | Jumlah volume, bukan kapasitas GiB |
| Elastic IPs | 0 | Tidak menunjukkan bahwa semua IPv4 publik bebas biaya |
| EC2 cost: Total cost | **USD 6,80** | Panel menampilkan **Past 6 months**, **Region: Global**; bukan biaya bulanan H8Mart |

**Kesimpulan atas screenshot:** USD 6,80 merupakan angka historis yang ditampilkan pada panel biaya EC2 dengan cakupan global selama enam bulan. Tidak boleh ditulis sebagai biaya bulanan H8Mart, biaya total semua layanan AWS, atau bukti bahwa tarif instance USD 0,0264/jam sudah benar. Angka tersebut dapat dipengaruhi masa pemakaian, kredit, jenis instance, dan cakupan panel. Untuk atribusi H8Mart diperlukan **AWS Billing/Cost Explorer** dengan periode, region, service, dan bila memungkinkan tag proyek yang tepat. Jangan menampilkan nomor akun, detail pembayaran, atau data rahasia dalam evidence publik.

### 3.3 Sumber harga dan status verifikasi

| Komponen | Sumber rujukan | Status pada dokumen |
|---|---|---|
| EC2 On-Demand | https://aws.amazon.com/ec2/pricing/on-demand/ | **Belum diverifikasi** tarif `t3.small`, Linux, Jakarta pada tanggal revisi |
| EBS gp3 | https://aws.amazon.com/ebs/pricing/ | **Belum diverifikasi** tarif Jakarta dan ukuran volume aktual |
| Public IPv4 | https://aws.amazon.com/vpc/pricing/ | Parameter USD 0,005/jam dari model; cek penerapan aktual |
| AWS Pricing Calculator | https://calculator.aws/ | Gunakan untuk estimasi spesifik region dan konfigurasi |
| AWS Free Tier | https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier.html | Kelayakan dan sisa kredit **harus dilihat di akun**, tidak diasumsikan |
| n8n | https://n8n.io/pricing/ | Enterprise memerlukan penawaran sesuai kebutuhan; USD 720 **bukan quotation** |
| OpenAI API | https://openai.com/api/pricing/ | Tarif harus dicocokkan dengan model nyata di WF3 |

**Tanggal dokumentasi:** 19 November 2026. Tanggal ini bukan bukti bahwa semua laman harga di atas sudah dicek langsung. Saat finalisasi, isi tanggal pemeriksaan aktual, mata uang, region, konfigurasi, dan tangkapan layar/kutipan harga pada evidence yang relevan.

## 4. Biaya LLM dan konsistensi dokumen 02

Model simulasi dokumen 02: 100 pertanyaan/bulan × 2.000 input token = **200.000 input token/bulan**; 100 × 400 output token = **40.000 output token/bulan**. Jika tarif pembanding adalah **USD 0,10 per juta input token** dan **USD 0,50 per juta output token**, biaya: `(0,2×0,10)+(0,04×0,50) = USD 0,04/bulan`, atau **USD 0,48/tahun**.

**Penting:** tarif di atas **parameter skenario**, bukan harga model yang sudah terverifikasi atau bukti model WF3. Sebelum pengumpulan, cek nama model dan harga resminya serta metrik usage OpenAI. Biaya belum memasukkan pemanggilan LLM berulang, retries, atau fitur tambahan.

| Skenario pemanggilan model | Input/bulan | Output/bulan | Biaya/bulan pada tarif simulasi |
|---|---:|---:|---:|
| 100 pertanyaan | 200.000 | 40.000 | USD 0,04 |
| 2.120 pertanyaan (seluruh interaksi diasumsikan memakai LLM) | 4.240.000 | 848.000 | USD 0,848 |

Perhitungan ROI dokumen 02 memakai **USD 130/bulan = USD 1.560/12** sebagai TCO dasar self-hosted yang telah memasukkan biaya admin, operasional, dan risiko. Jangan menambahkan lagi biaya admin/operasional yang sama ke ROI. Biaya implementasi awal USD 120 pada dokumen 02 adalah asumsi terpisah; jangan diklaim sudah tercakup TCO dasar.

## 5. Dasar regulasi dan implikasi kepatuhan

**Konteks:** milestone menggunakan data sintetis. Penggunaan data pelanggan nyata akan menimbulkan kewajiban tambahan yang perlu ditinjau oleh penanggung jawab hukum/privasi. Referensi hukum di bawah adalah titik pemeriksaan kepatuhan, **bukan pernyataan bahwa audit hukum telah selesai**.

| Regulasi dan ketentuan | Relevansi keputusan | Bukti/kontrol yang perlu dipersiapkan |
|---|---|---|
| **UU No. 27 Tahun 2022 tentang Pelindungan Data Pribadi, Pasal 35** | Kewajiban pengendali data pribadi melindungi dan memastikan keamanan data pribadi yang diproses | Pembatasan akses, pengamanan credential, enkripsi, pengelolaan hak akses, dokumentasi kontrol |
| **UU No. 27 Tahun 2022, Pasal 46** | Kewajiban pemberitahuan dalam hal terjadi kegagalan pelindungan data pribadi, sesuai ketentuan pasal | Prosedur insiden, pencatatan waktu kejadian, alur eskalasi dan pemberitahuan |
| **PP No. 71 Tahun 2019 tentang Penyelenggaraan Sistem dan Transaksi Elektronik** | Kerangka kewajiban penyelenggaraan sistem elektronik; pasal spesifik yang berlaku harus ditetapkan melalui telaah hukum sesuai status dan kegiatan penyelenggara | Kebijakan operasi, keandalan sistem, pengamanan dan audit trail |

**Sumber naskah hukum resmi untuk pengecekan pasal:** https://peraturan.bpk.go.id/ (cari UU 27/2022 dan PP 71/2019). Nomor dan rumusan pasal harus dicocokkan dengan naskah resmi sebelum dokumen dinyatakan sebagai analisis kepatuhan final. Jangan menganggap pilihan cloud, self-hosted, atau on-premise dengan sendirinya memenuhi hukum.

## 6. Keputusan deployment dan batas keputusan

**Dipilih: self-hosted AWS EC2 + Docker Compose untuk Milestone 3.** Pertimbangan: (1) TCO simulasi terendah, (2) layanan n8n, PostgreSQL, Mock API, Uptime Kuma, task runners, dan Caddy dapat dijalankan pada jaringan internal yang terkendali, (3) kontrol akses `mcp_reader` read-only dan `ops_writer` untuk operasi tulis dapat diuji, dan (4) instruktur dapat menguji Production Webhook HTTPS tanpa akses editor n8n/database.

**Keputusan readiness:** *belum ada dasar untuk menyatakan GO produksi nyata*. GO/GO BERSYARAT/NO-GO harus ditetapkan melalui item dan bukti `docs/04-readiness-checklist.md`. Keputusan deployment teknis untuk Milestone **tidak sama** dengan persetujuan operasional bisnis nyata. Jika bukti atau persetujuan belum tersedia, tandai belum diverifikasi; jangan mengarang sign-off stakeholder.

## 7. Rencana deployment dan keamanan

| Aspek | Konfigurasi / tindakan |
|---|---|
| Infrastruktur | EC2 `t3.small`, Ubuntu Server 24.04 LTS, region Jakarta (per dashboard). Cocokkan instance H8Mart melalui EC2 Instances, bukan hanya ringkasan 2 instance. |
| Compose | `docker compose -f compose.yaml -f compose.vps.yaml ps` pada direktori proyek |
| Layanan | `n8n`, `task-runners`, `postgres`, `mock-api`, `uptime-kuma`, `caddy`; cocokkan nama dan status dengan output nyata |
| HTTPS | `https://h8mart-syifa.duckdns.org` via Caddy; uji `curl -I` dan sertifikat |
| Jaringan | Publik hanya port yang diperlukan (misalnya 80/443 dan SSH yang dibatasi); PostgreSQL dan Mock API tidak dipublikasikan sembarangan |
| Database | `mcp_reader` untuk SELECT MCP; `ops_writer` untuk node PostgreSQL yang menulis; uji INSERT `mcp_reader` ditolak |
| Credential | Simpan password/token di n8n Credentials atau konfigurasi server terlindungi; jangan commit `.env`, credential ID, token, atau screenshot rahasia |
| Webhook | WF1 dan WF3 menggunakan Production URL; salin WF4 dari node aktual; lindungi sesuai kontrak header auth |
| Monitoring | Uptime Kuma, WF5 Error Trigger, Telegram alert, Notification API, executions |
| Backup | Rencanakan `pg_dump`, backup volume dan encryption key, penyimpanan terpisah serta uji restore; **belum klaim berhasil tanpa bukti** |
| AWS Budget | Tetapkan alarm dan tinjau biaya/kredit; alarm tidak otomatis menghentikan tagihan |
| Jadwal | WF1A 15 menit, digest 07.00 WIB; verifikasi timezone `Asia/Jakarta` dan status Published |

## 8. Bukti yang harus dilampirkan

| ID | Bukti | Lokasi evidence yang disarankan | Status |
|---|---|---|---|
| DEP-01 | Screenshot EC2 Dashboard (region Jakarta, 2 running, EC2 cost USD 6,80 / past 6 months) | `evidence/deploy/01-ec2-dashboard.png` | **Screenshot tersedia dalam percakapan; belum dipastikan tersimpan di repo** |
| DEP-02 | EC2 Instances: pilih instance H8Mart, jenis `t3.small`, region, volume, status | `evidence/deploy/02-h8mart-instance.png` | Perlu dilampirkan |
| DEP-03 | `docker compose -f compose.yaml -f compose.vps.yaml ps` | `evidence/deploy/03-compose-ps.png` | Perlu dicocokkan dengan bukti terbaru |
| DEP-04 | HTTPS dan sertifikat, `curl -I` | `evidence/deploy/04-https.png` | Perlu dilampirkan |
| DEP-05 | AWS Billing/Cost Explorer dengan periode dan cakupan yang jelas | `evidence/deploy/05-billing-period.png` | Perlu dilampirkan; redaksi informasi sensitif |
| DEP-06 | AWS Budgets/Credits | `evidence/deploy/06-budgets-credits.png` | Perlu dilampirkan |
| DB-01 | SQL stok 205, NULL 0, duplikat 0 | `evidence/wf1/stock-quality.png` | Hasil pernah dilaporkan; simpan screenshot terbaru |
| DB-02 | `ops.dead_letter` dan uji INSERT `mcp_reader` ditolak | `evidence/wf1/dead-letter.png`, `evidence/wf2/mcp-reader-denied.png` | Perlu dilampirkan |
| API-01 | Respons `/admin/stock-calls` | `evidence/wf1/stock-calls.png` | Perlu dilampirkan |
| WF-03 | WF3 response field `status`, tiket/eskalasi, Telegram, executions | `evidence/wf3/` | Perlu dilampirkan |
| WF-05 | WF5 error workflow dan alert | `evidence/wf5/` | Perlu dilampirkan |
| COST-01 | Harga EC2/EBS/IP khusus Jakarta, tanggal pemeriksaan | `evidence/deploy/07-pricing-jakarta.png` | Belum diverifikasi |
| COST-02 | Nama model WF3, tarif resmi, dan penggunaan token | `evidence/wf3/llm-usage.png` | Belum diverifikasi |

**Catatan evidence:** Nama file adalah **usulan path**, bukan pernyataan bahwa berkas sudah dibuat. Bukti per baris readiness A1–O4 dipetakan lebih rinci dalam `docs/04-readiness-checklist.md`.

## 9. Risiko, mitigasi, dan kondisi yang dapat mengubah keputusan

| Risiko | Dampak | Mitigasi / kriteria peninjauan |
|---|---|---|
| Perbandingan harga tidak setara | Keputusan biaya menyesatkan | Peroleh quotation cloud, harga region Jakarta, dan spesifikasi on-premise yang setara |
| Dua instance aktif tetapi biaya dihitung satu | TCO aktual lebih tinggi | Identifikasi instance H8Mart dan atribusi biaya dengan tag/Cost Explorer |
| Kredit AWS habis | Tagihan kas meningkat | Pantau Billing, Budgets, Credits; estimasi biaya tanpa kredit |
| EC2 kehabisan RAM/CPU | Workflow gagal atau lambat | `docker stats`, monitoring, optimasi atau upgrade instance |
| LLM lebih sering dipanggil | Biaya meningkat | Ukur token aktual, retry, dan frekuensi model calls |
| Backup belum pernah diuji restore | Risiko kehilangan data | Jadwalkan dan dokumentasikan restore test |
| Token atau credential terekspos | Penyalahgunaan layanan | Sanitasi repo, rotasi secret, least privilege |
| Approval refund/error handling tidak lengkap | Risiko transaksi dan layanan | Uji jalur approve/reject/idempotensi dan WF5 |
| Penggunaan data nyata tanpa kebijakan | Risiko kepatuhan | Telaah hukum, prosedur insiden, retensi, pengamanan dan persetujuan internal |

## 10. Kesimpulan

**Self-hosted AWS EC2 dipilih untuk kebutuhan Milestone H8Mart**, dengan TCO simulasi 12 bulan termasuk LLM **USD 1.560,48**. Selisih terhadap cloud simulasi **USD 7.270/tahun**. Screenshot AWS memperlihatkan **USD 6,80 pada panel EC2, Past 6 months, Region Global**, sehingga tidak boleh dipakai sebagai biaya bulanan H8Mart. TCO ini adalah alat keputusan berbasis asumsi, bukan realisasi biaya. Kesiapan produksi, verifikasi harga Jakarta, biaya token aktual, kontrol keamanan, dan bukti per item readiness harus dituntaskan sebelum keputusan GO/GO BERSYARAT/NO-GO.

## 11. Daftar sumber

1. Materi Hands-on Hacktiv8 Phase 3 Week 2 Day 3 — kerangka perhitungan TCO dan keputusan deployment (asumsi laboratorium).
2. AWS EC2 On-Demand Pricing: https://aws.amazon.com/ec2/pricing/on-demand/
3. AWS EBS Pricing: https://aws.amazon.com/ebs/pricing/
4. AWS VPC Pricing: https://aws.amazon.com/vpc/pricing/
5. AWS Pricing Calculator: https://calculator.aws/
6. AWS Free Tier: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier.html
7. n8n Pricing: https://n8n.io/pricing/
8. OpenAI API Pricing: https://openai.com/api/pricing/
9. UU No. 27 Tahun 2022 dan PP No. 71 Tahun 2019, naskah resmi: https://peraturan.bpk.go.id/
10. Dokumen proyek: `docs/02-desain-solusi-roi.md`, `docs/04-readiness-checklist.md`, `guide/submission.md`, `data-contract.md`.
11. Screenshot AWS EC2 Dashboard yang diberikan pada 19 November 2026 (panel Resources dan EC2 cost).
