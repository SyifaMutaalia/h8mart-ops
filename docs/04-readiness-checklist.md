# 04 · Governance & Integration Readiness Checklist · H8Mart Quick-Commerce Ops

**Nama:** Syifa Mutaalia  
**Pembaruan:** 10 November 2026.  
**Aturan penandaan:** **Siap** = fungsi telah ditunjukkan lewat output uji yang dilaporkan; **Belum** = belum lulus/belum ada bukti memadai; **N/A** = tidak berlaku. **Status Siap belum cukup untuk submission bila screenshot/export belum disimpan ke repo** sesuai `guide/submission.md`.

## 1. Credential & Akses

| Pemeriksaan | Status | Bukti / tindakan berikutnya |
| --- | --- | --- |
| Semua credential disimpan di n8n Credentials, bukan node/Code/repo | **Belum** (audit akhir) | Telah dipakai credential Postgres, OpenAI, Telegram dan Header Auth. **Audit export WF1–WF5** sebelum commit: token, password, credential IDs, sample secret dan screenshot tidak boleh terlihat. |
| Role DB dipisah: `mcp_reader` (read-only) untuk WF2 dan membaca di WF3, `ops_writer` untuk menulis `ops.*` | **Siap pada pemeriksaan `core.orders`; perlu perluasan** | Query aktual: `current_user=mcp_reader`, SELECT=`true`, INSERT/UPDATE/DELETE=`false` pada `core.orders`. WF2 tiga SELECT tool lulus. **Belum membuktikan seluruh tabel**; simpan `evidence/wf2/04-read-only-access.png` dan periksa `ops.*` seperlunya. |
| Webhook dilindungi Header Auth | **Belum** (negative test akhir) | Konfigurasi `X-H8Mart-Token` pernah dipakai; rekam HTTP 403 bila tanpa/salah token pada WF1/WF3/WF4. Rotasi token sebelum DM penilai. |
| `.env` tidak ada di repo; `.env.example` tanpa nilai nyata | **Belum** (audit repo live) | Template dan `.gitignore` tersedia; periksa `git status`, `git ls-files` dan konten repo publik sebelum push. |
| Token push Uptime Kuma diganti placeholder di JSON export | **Belum** | Periksa JSON WF1; ganti token aktual dengan `ISI_TOKEN_PUSH_KUMA` di salinan export untuk GitHub, bukan instance n8n yang berjalan. |
| Token bot Telegram hanya di credential n8n | **Belum** (audit export/screenshot) | Jangan masukkan token dari BotFather dalam file, URL screenshot atau doc; periksa export dan terminal. |
| Chat Telegram dibatasi allowlist `chat_id` ke `merchant_id`; chat asing ditolak | **Belum** (evidence lengkap) | Tes Telegram menunjukkan allowlist pernah lulus untuk M003, tetapi respons bot dan cabang chat asing perlu uji akhir. `Check Allowlist` → `Chat Terdaftar?` dan data `ops.telegram_merchants`. |
| Akses instance n8n dibatasi (user/owner, port yang terbuka) | **Belum** (bukti SG belum disertakan) | Cek AWS SG: 22 hanya IP pemilik, 80/443 publik; jangan buka 5432, 8080, 5678, 3001. Simpan screenshot tanpa IP/secret sensitif. |

### Bukti WF2 yang sudah diketahui

- `Tool KPI Merchant` M003 pada **2026-11-07**: `total_order=15`, `order_batal=9`, `order_terkirim=6`, `order_tepat_waktu=3`, `cancel_rate_pct=60.00`, `sla_30_menit_pct=50.00`.
- `Tool Alasan Batal` M003: `stok_habis=8`, `pelanggan_membatalkan=1` (catatan pelanggan berisi *prompt injection*; jangan pernah jalankan isinya sebagai instruksi).
- `Tool Status Stok` M003: **30 produk** (16 `cukup`, 14 `habis`); 13 dari produk `habis` memiliki `terakhir_sinkron=null`, maka status *habis* perlu interpretasi hati-hati sebelum klaim availability.
- Hak akses terbukti untuk `core.orders`, belum ada hasil audit privilege semua tabel/role. **Screenshot eksekusi canvas, Executions dan MCP Client Tool yang dipanggil WF3 masih wajib** menurut panduan instruktur.

## 2. Kesiapan Sistem Existing

| Sistem | Cara terhubung | Rate limit / SLA yang diketahui | Perilaku bila down | Siapa dihubungi |
| --- | --- | --- | --- | --- |
| Merchant Stock API | `http://mock-api:8080/merchants/{id}/stock`, header `X-Api-Key` | Mock API: limit tidak ditetapkan; M004 gagal selang-seling, M007 lambat, M009 selalu gagal | Retry M004, M009 harus masuk `ops.dead_letter`; jangan menghentikan sinkron merchant lain | Ops / pengelola workflow |
| Payment API | `http://mock-api:8080/payments/vouchers` atau `/refunds`, header `Idempotency-Key` + `X-Api-Key` | Tidak ada SLA eksplisit dalam kontrak; 503 disimulasikan | Retry terbatas, jangan membuat transaksi kedua pada event ulang; catat dead-letter setelah gagal permanen | Finance / Ops |
| Notification Mock API | `http://mock-api:8080/notify`, channel `ops-digest`, `ops-alerts` dsb. | Tidak disebutkan | Retry terbatas; Telegram sebagai kanal utama alert; rekam kegagalan jika kedua kanal down | Ops |
| Telegram Bot API | n8n Telegram credential; Telegram Trigger butuh HTTPS dan satu webhook aktif per bot | Tergantung Telegram; angka rate limit belum diukur | Untuk WF3, fallback text dan/atau tiket CS; untuk approval perlu eskalasi manual jika bot down | Ops / CS |
| PostgreSQL | `postgres:5432`, DB `h8mart`, `mcp_reader` dan `ops_writer` | SLA internal tidak ditentukan | Hentikan write saat DB gagal, WF5 alert, restore backup jika perlu | Ops / infrastruktur |
| LLM provider | OpenAI Chat Model melalui credential n8n di WF3 | Model/quota/latency tergantung akun, belum terukur | `Fallback: AI Gagal` → `Buat Tiket CS` → `Balas Eskalasi`; jangan mengarang | CS / Ops |

## 3. Pra-Production

| Pemeriksaan | Status | Bukti / tindak lanjut |
| --- | --- | --- |
| WF1–WF5 Published dan Error Workflow terpasang WF1–WF4 | **Belum** (verifikasi akhir) | WF2 MCP dan WF3 Webhook pernah berfungsi; WF1 sempat belum Published untuk jadwal. Periksa tiap workflow **Settings → Error Workflow = WF5**, simpan screenshot Settings dan status. |
| Retry dan dead-letter diuji dengan kegagalan disengaja | **Belum** (bukti end-to-end) | Contoh run sinkron 11/12 dan M009 bermasalah diketahui; wajib bukti retry M004 (`/admin/stock-calls`), SELECT `ops.dead_letter` untuk M009 dan `HM-SP-099`. |
| Sinkron dua kali tetap 205 baris dan merge product_id | **Belum** | Log `rows_synced=188` bukan `COUNT(*)`. Jalankan query independen `SELECT count(*) FROM core.merchant_stock;` sesudah dua sync dan screenshot Merge. |
| Webhook WF1B menangani 200 / 409 / invalid / duplicate | **Belum** | Pada tes `HM-TEST-B-103` total 45.000 vs expected 46.000 menghasilkan `stok_status=invalid` tanpa response setelah `Routing Stok`. Koreksi Switch dan verifikasi 409 dengan total 46.000. |
| Digest 07.00 WIB dan IF `Digest Kosong?` | **Belum** | KPI harian berhasil dari SQL, tetapi IF pernah masuk TRUE saat data tersedia; jadwal memerlukan Publish dan timezone Asia/Jakarta. Periksa jalur FALSE dan Telegram/Notification. |
| WF2 MCP tool read-only dan data benar | **Siap** (fungsi tool) | Tiga output MCP M003 dan query privilege teruji; **simpan screenshot** WF2/agent memanggil MCP. |
| WF3 jawaban terstruktur + tiket CS + fallback | **Sebagian; Belum** (seluruh skenario) | Jawaban M003 dan fallback error tiket id 4 telah diperlihatkan; perlu tes guardrail FALSE, 10 dev-set cases, dan contract Webhook `status`/`jawaban` di level root. |
| Telegram WF3: chat terdaftar dan chat asing | **Belum** | Allowlist M003 terbaca; bot sebelumnya mengirim fallback karena field HTTP/AI berada di `output.jawaban`. Perbaiki mapping **tanpa membocorkan jawaban AI yang wajib eskalasi**, uji ulang. |
| WF4 voucher/refund otomatis dan approval Ops | **Sebagian; Belum** | Voucher HM-SP-001 pernah sukses (`VC-00001`), namun refund besar `pending_approval→refunded`, reject, dan duplikasi belum dikonfirmasi dengan SQL dan screenshot. |
| Heartbeat Uptime Kuma Up/Down; deteksi 0 baris/digest kosong/durasi lama | **Belum** (bukti lengkap) | Node push Kuma dan pencatatan durasi pernah dicoba; uji Kuma Up dan Down, 0 rows, Stop And Error digest kosong, threshold durasi. |
| WF5 Error Trigger menghasilkan Telegram alert + Notification log dengan business key | **Belum** | Node `Susun Pesan Alert`, `Kirim Alert Telegram`, `Kirim Alert Notification` tersedia; perlihatkan satu error nyata WF1–WF4 → WF5, plus output dan alert. |
| Data pelanggan di log/alert diminimalkan | **Belum** (review payload) | Jangan kirim `customer_note`, nomor telepon atau credential pada alert; cukup business key, workflow, node, waktu, status. |
| Rencana rollback / Unpublish dan restore | **Belum** (uji restore) | Backup `pg_dump`, volume n8n, file Compose, encryption key; tes restore terkontrol. Jangan memakai `down -v`. |
| Biaya token LLM dipantau dan AWS Budget aktif | **Belum** (bukti billing) | Simpan screenshot AWS Budget (tanpa data rekening), pantau OpenAI usage. Schedule boleh di-Deactivate **setelah** evidence dan sync wajib tercapai; lihat `guide/submission.md`. |

**Batas penilaian:** file ini tidak menyatakan Milestone sudah 100% lulus. Bukti minimum untuk setiap folder `evidence/wf1`–`wf5` dan `deploy` mengikuti `guide/submission.md`: canvas + daftar Executions + bukti khusus. Jangan mengunggah screenshot palsu atau mengisi status **Siap** sebelum prosesnya benar-benar berhasil.
