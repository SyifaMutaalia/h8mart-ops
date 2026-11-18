# 02 · Desain Solusi + Solution Fit + ROI
## H8Mart Quick-Commerce Ops

**Nama:** Syifa Mutaalia  
**Workflow:** WF1 Stock Sync, Order Intake & Digest; WF2 Merchant Data Tools; WF3 AI Merchant Assistant; WF4 Kompensasi & Refund; WF5 Reliability & Monitoring.  
**Pembaruan:** 19 November 2026  
**Status:** Evaluasi desain dan simulasi finansial. Hasil pengujian dipisahkan dari estimasi biaya dan manfaat.

## 1. Arsitektur Solusi

H8Mart menggunakan lima workflow n8n yang diintegrasikan dengan PostgreSQL, Mock API, OpenAI API, Telegram, dan Uptime Kuma. Sistem dijalankan menggunakan Docker Compose pada AWS EC2 dengan Caddy sebagai reverse proxy HTTPS.

| Workflow | Fungsi utama | Integrasi |
|---|---|---|
| WF1 | Sinkronisasi stok, validasi order, dan laporan harian | PostgreSQL, Merchant Stock API, Uptime Kuma |
| WF2 | Menyediakan data merchant melalui MCP secara read-only | PostgreSQL, `mcp_reader` |
| WF3 | Menjawab pertanyaan merchant dan membuat tiket eskalasi | OpenAI, MCP, PostgreSQL, Telegram |
| WF4 | Menentukan voucher/refund berdasarkan aturan dan persetujuan Ops | Payment API, PostgreSQL, Telegram |
| WF5 | Mendeteksi dan melaporkan kegagalan workflow | Error Trigger, Telegram, Notification API |

**Deployment:** AWS EC2 Ubuntu 24.04, Docker Compose, Caddy HTTPS, n8n, PostgreSQL, Mock API, dan Uptime Kuma.

**Domain:** https://h8mart-syifa.duckdns.org

Koneksi antarlayanan dalam Docker menggunakan nama service internal, seperti `postgres`, `n8n`, dan `mock-api`.

### 1.1 Hasil pengujian yang dilaporkan

| Workflow | Hasil yang telah diperoleh | Batasan verifikasi |
|---|---|---|
| WF1A | Sinkronisasi 12 merchant, 11 berhasil, 188 baris pada contoh run; tabel stok pernah berisi 205 baris tanpa `product_id` NULL atau pasangan duplikat | Perlu bukti retry, dead-letter, dan eksekusi terbaru |
| WF1C | 162 order, 25 batal, 134 terkirim, SLA 82,84% pada sampel | Logika IF digest perlu dibuktikan setelah perbaikan |
| WF2 | Tiga MCP tool menghasilkan data merchant M003; pengujian hak akses menunjukkan pembatasan operasi tulis | Lampirkan hasil SQL role |
| WF3 | Jawaban merchant M003 dan pembuatan tiket eskalasi pernah berhasil | Perlu bukti respons `status`, Telegram, dan error handling terbaru |
| WF4 | Voucher HM-SP-001 menghasilkan `VC-00001` | Approval, reject, dan idempotensi memerlukan evidence |
| WF5 | Error Trigger dan notifikasi telah dikonfigurasi | Keberhasilan end-to-end perlu didukung executions |

Hasil di atas merupakan catatan pengujian yang dilaporkan, bukan bukti bahwa seluruh acceptance criteria telah lulus.

## 2. Solution Fit dan Keputusan Otomasi

| Kode | Keputusan bisnis | Pendekatan | Alasan |
|---|---|---|---|
| D1 | Validitas order, harga, dan ketersediaan stok | Rule-based | Memerlukan keputusan deterministik dan idempotensi |
| D2 | Ketersediaan data digest dan perhitungan KPI | Rule-based | Agregasi dan ambang KPI dihitung dari SQL |
| D3 | Voucher, refund, dan kebutuhan persetujuan | Rule-based + manusia | Keputusan finansial tertentu harus disetujui Ops |
| D4 | Penjelasan penyebab pembatalan pesanan merchant | AI + MCP read-only | LLM merangkum data terverifikasi dalam bahasa alami |
| D5 | Validasi jawaban AI dan eskalasi | Guardrail + CS | Jawaban tidak valid atau data tidak cukup dialihkan ke CS |

Penggunaan AI dibatasi pada interpretasi dan penyusunan jawaban berbasis data. Validasi transaksi, penentuan nominal kompensasi, dan keputusan persetujuan tetap menggunakan aturan deterministik atau manusia.

## 3. Estimasi Manfaat dan Return on Investment (ROI)

### 3.1 Asumsi perhitungan

Perhitungan menggunakan skenario perencanaan, bukan data timesheet atau tagihan aktual.

| Parameter | Asumsi |
|---|---:|
| Hari kerja | 22 hari/bulan |
| Tarif tenaga kerja | USD 15/jam |
| Laporan Ops | 1 laporan/hari |
| Pertanyaan merchant | 100 pertanyaan/bulan |
| Kasus voucher/refund | 80 kasus/bulan |
| Penghematan waktu laporan | 75% |
| Penghematan waktu CS | 65% |
| Penghematan waktu kompensasi | 60% |
| Biaya platform simulasi | USD 130/bulan |
| Biaya implementasi awal | USD 120 |

### 3.2 Estimasi penghematan waktu

| Aktivitas | Rumus | Penghematan |
|---|---|---:|
| Laporan Ops | 45 × 22 × 75% / 60 | 12,375 jam |
| Pertanyaan merchant | 8 × 100 × 65% / 60 | 8,667 jam |
| Voucher/refund | 12 × 80 × 60% / 60 | 9,600 jam |
| **Total** | | **30,642 jam/bulan** |

Estimasi manfaat tenaga kerja:

`30,6417 jam × USD 15 = USD 459,63/bulan`

Nilai tersebut adalah potensi kapasitas kerja yang dihemat, bukan otomatis pengurangan pengeluaran kas atau pengurangan jumlah pegawai.

### 3.3 Estimasi biaya LLM WF3

Biaya LLM dihitung berdasarkan volume pertanyaan, jumlah token input/output, dan tarif model yang digunakan.

**Asumsi penggunaan:**

| Parameter | Nilai |
|---|---:|
| Permintaan merchant | 100/bulan |
| Input per permintaan | 2.000 token |
| Output per permintaan | 400 token |
| Total input | 200.000 token/bulan |
| Total output | 40.000 token/bulan |
| Model pembanding | GPT-6 Luna |
| Tarif input standar | USD 0,10/1 juta token |
| Tarif output standar | USD 0,50/1 juta token |

**Sumber harga:** OpenAI API, https://openai.com/api/  
**Tanggal pemeriksaan:** 19 November 2026.

Tarif model pembanding bukan konfirmasi model yang digunakan dalam node OpenAI WF3. Identitas model dan tarif final harus disesuaikan dengan konfigurasi workflow.

**Rumus biaya:**

`Biaya LLM = (Token input / 1.000.000 × Tarif input) + (Token output / 1.000.000 × Tarif output)`

Perhitungan:

- Input: 200.000 / 1.000.000 × USD 0,10 = USD 0,02
- Output: 40.000 / 1.000.000 × USD 0,50 = USD 0,02
- **Total estimasi LLM = USD 0,04/bulan**
- **Estimasi tahunan = USD 0,48**

Perhitungan mengasumsikan satu pemanggilan model per pertanyaan, tanpa biaya tool tambahan, retry, maupun pemanggilan LLM berulang. Prompt caching tidak dimasukkan sebagai diskon agar asumsi tetap sederhana.

**Status penggunaan aktual:** Belum diukur. Jumlah token sebenarnya harus diperoleh dari OpenAI Usage Dashboard atau metadata pemakaian model pada executions WF3.

### 3.4 Sensitivitas biaya LLM

| Volume pertanyaan/bulan | Token input | Token output | Estimasi biaya |
|---|---:|---:|---:|
| 100 | 200.000 | 40.000 | USD 0,04 |
| 500 | 1.000.000 | 200.000 | USD 0,20 |
| 1.000 | 2.000.000 | 400.000 | USD 0,40 |
| 5.000 | 10.000.000 | 2.000.000 | USD 2,00 |

Simulasi menunjukkan biaya token relatif kecil pada model dan asumsi tersebut. Namun, total biaya dapat meningkat apabila workflow melakukan beberapa panggilan model, memakai model lain, atau membutuhkan proses tambahan.

### 3.5 Perhitungan manfaat bersih

| Komponen | Nilai bulanan |
|---|---:|
| Potensi manfaat tenaga kerja | USD 459,63 |
| Biaya platform simulasi | USD 130,00 |
| Estimasi biaya LLM | USD 0,04 |
| **Manfaat bersih operasional** | **USD 329,59** |

Biaya platform USD 130/bulan mengacu pada simulasi TCO self-hosted sebesar USD 1.560/tahun dalam dokumen 03.

**Asumsi penting:** Biaya platform tersebut dianggap belum memasukkan biaya LLM. Biaya implementasi awal USD 120 juga diasumsikan belum termasuk dalam TCO tersebut. Komponen biaya harus direkonsiliasi dengan dokumen 03 untuk mencegah penghitungan ganda.

**Payback period:**

`USD 120 / USD 329,59 = 0,36 bulan`

**ROI tahun pertama:**

Manfaat bersih tahunan sebelum investasi awal:

`USD 329,585 × 12 = USD 3.955,02`

Setelah biaya implementasi awal:

`USD 3.955,02 - USD 120 = USD 3.835,02`

ROI dihitung menggunakan investasi dan biaya yang didefinisikan secara eksplisit:

`ROI = (Manfaat tahunan - biaya operasional tahunan - investasi awal) / (biaya operasional tahunan + investasi awal) × 100%`

`ROI = (5.515,50 - 1.560,48 - 120) / (1.560,48 + 120) × 100%`

**ROI simulasi tahun pertama ≈ 228,2%.**

Nilai tersebut bersifat ilustratif, bukan ROI aktual perusahaan. Hasilnya hanya berlaku apabila asumsi volume aktivitas, tarif tenaga kerja, penghematan waktu, dan biaya benar-benar tercapai.

### 3.6 Skenario risiko ROI

Apabila volume penggunaan hanya 20% dari asumsi dan manfaat tenaga kerja turun secara proporsional:

- Manfaat tenaga kerja ≈ USD 91,93/bulan
- Biaya platform = USD 130/bulan
- Biaya LLM ≈ USD 0,008/bulan
- Manfaat bersih ≈ negatif USD 38,08/bulan

Dengan demikian, solusi belum tentu menghasilkan manfaat finansial positif pada volume penggunaan rendah. Evaluasi produksi perlu memperhitungkan volume riil, biaya operasional, frekuensi error, waktu penanganan manual, dan kualitas respons AI.

## 4. Risiko dan Batas Otomasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Status order invalid/duplicate tidak ditangani | Respons API tidak sesuai kontrak | Validasi status 200/409/422 dan idempotensi |
| Kondisi IF digest salah | Laporan tidak terkirim | Perbaikan kondisi dan pengujian ulang |
| Merchant API gagal | Data stok tidak mutakhir | Retry, dead-letter, dan notifikasi |
| Data stok tidak tersedia | AI menyatakan stok habis secara keliru | Bedakan data kosong dan kuantitas nol |
| Prompt injection | AI menghasilkan informasi tidak sah | Guardrail dan pembatasan MCP read-only |
| Eskalasi diabaikan | Jawaban AI tidak aman diteruskan | Prioritaskan `perlu_eskalasi` |
| Refund ganda | Kerugian transaksi | Idempotency-Key dan unique constraint |
| Credential bocor | Penyalahgunaan akses | Credentials n8n, rotasi secret, dan sanitasi export |
| Server tidak tersedia | Workflow gagal diakses | Uptime Kuma, alert, dan pemantauan EC2 |

## 5. Kesimpulan Solution Fit

Arsitektur lima workflow H8Mart sesuai dengan kebutuhan otomasi stok, order, pelaporan, layanan merchant, kompensasi, dan monitoring dalam skenario Milestone.

Pendekatan rule-based digunakan untuk keputusan yang membutuhkan konsistensi transaksi, sedangkan AI digunakan untuk menjelaskan informasi merchant berdasarkan data yang diakses melalui MCP read-only.

Berdasarkan simulasi, manfaat tenaga kerja diperkirakan USD 459,63/bulan dengan biaya platform dan LLM sebesar USD 130,04/bulan, menghasilkan manfaat bersih sekitar USD 329,59/bulan.

**Kesimpulan finansial masih bersifat estimasi**, bukan bukti penghematan aktual. Keputusan kelayakan deployment harus mempertimbangkan hasil pengujian workflow, readiness checklist, dan verifikasi biaya pada dokumen 03 dan 04.

## 6. Referensi dan Bukti Pendukung

1. OpenAI. *API Pricing*. https://openai.com/api/ — diperiksa 19 November 2026.
2. OpenAI. *API Pricing Documentation*. https://developers.openai.com/api/docs/pricing
3. H8Mart Milestone 3. `README.md`, `data-contract.md`, dan `guide/submission.md`.
4. H8Mart. `docs/03-tco-deployment.md` — asumsi TCO dan biaya deployment.
5. H8Mart. `docs/04-readiness-checklist.md` — hasil evaluasi kesiapan.
6. H8Mart. `evidence/wf1/` sampai `evidence/wf5/` — bukti pengujian workflow.
7. H8Mart. `evidence/deploy/` — bukti deployment HTTPS dan Docker Compose.

**Bukti yang masih diperlukan untuk finalisasi:** screenshot model OpenAI pada WF3, jumlah token penggunaan aktual, bukti executions terbaru, dan verifikasi komponen biaya TCO agar tidak dihitung dua kali.