# Pengumpulan Milestone

[Guide](README.md) · [Soal bagian 5](../README.md#5-yang-dikumpulkan)

Langkah singkat mengumpulkan ada di [soal bagian 5](../README.md#5-yang-dikumpulkan). Halaman ini berisi rinciannya: bukti yang diminta, checklist, dan format DM.

## Evidence

**Evidence** (per workflow, file **bernomor**, mis. `evidence/wf4/03-approval-pending.png`). Setiap folder `wf1` sampai `wf5` berisi: (1) **satu screenshot canvas** setelah dijalankan (node hijau, status Published terlihat), (2) **satu screenshot daftar Executions**, dan (3) **bukti spesifik** di tabel berikut. Kolom Minimum menentukan Meet Expectations; kolom Nilai penuh menambah nilai bila buktinya ada. Hal lain (video demo, skenario tambahan) tidak menambah poin.

| Folder | Bukti spesifik minimum (Meet Expectations) | Bukti nilai penuh |
| --- | --- | --- |
| `wf1/` | `count(*)` `core.merchant_stock` tetap 205 setelah dua sinkron, dengan `product_id` hasil Merge (katalog `core.products` lewat `sku`) terisi dan output node Merge terlihat; **retry**: satu panggilan Merchant Stock API gagal lalu berhasil (Executions + `GET /admin/stock-calls`); order ditolak stok habis (409) dan diterima (200); screenshot chat digest Telegram | produk baru habis terdeteksi; order stok tipis; order ganda tidak membuat baris ganda; digest cocok dengan SQL independen |
| `wf2/` | satu eksekusi WF2 yang dipicu agent WF3 lewat MCP Client Tool (tool dan parameternya terlihat) | `INSERT` lewat `mcp_reader` ditolak; satu run MCP Client (digest WF1) |
| `wf3/` | satu eksekusi dijawab dengan output terstruktur; satu eskalasi (+ baris `ops.tickets`); satu fallback | tabel dev set 10 kasus (aktual vs label); kasus injeksi; percakapan Telegram dan penolakan `chat_id` asing; Executions workflow chat yang dipicu Telegram Trigger (n8n Workflow Build) |
| `wf4/` | `ops.compensations`/`ops.refund_actions`: voucher otomatis dan refund besar `pending_approval` lalu `refunded`; screenshot chat approval Telegram sebelum dan sesudah klik (alternatif Wait node: Executions yang menunggu lalu lanjut setelah resume URL dibuka) | kirim dua kali tetap satu; reject; nominal refund = `total_amount`; retry Payment |
| `wf5/` | `SELECT * FROM ops.dead_letter` (merchant M009 yang selalu gagal dan order `HM-SP-099`); alert Telegram dengan business key; Executions Error Workflow; Kuma Up dan Down; sinkron 0 baris atau digest kosong; satu alert ambang durasi | kedua deteksi diam-diam |
| `deploy/` | browser HTTPS valid, `docker compose ps` di VPS, `curl` Production URL dari luar jaringan VPS | |

## Smoke test penilai

**Penilaian = isi repo + smoke test ke Production URL terbatas.** Penilai tidak punya akses ke database, mock API, atau editor n8n kalian. Smoke test hanya lewat Production URL: satu `order.created` diterima, satu `order.created` ditolak karena stok habis, dua pertanyaan WF3 (satu kasus tersembunyi), satu `delivery.late`, dan satu `order.failed` besar. Pastikan sinkron stok sudah berjalan minimal sekali di instance VPS supaya stok habis terdeteksi (setelah itu node Schedule boleh di-Deactivate, lihat *Cegah banjir alert dan digest*), dan kelima workflow **Published**.

## Cegah banjir alert dan digest

Setelah evidence diambil **dan sinkron stok sudah berjalan minimal sekali di instance VPS**, matikan dua Schedule Trigger di WF1 (sinkron 15 menit dan digest 07.00): klik kanan node › **Deactivate**, lalu **Publish** ulang WF1 supaya berlaku. Webhook order tetap hidup, jadi jangan Unpublish WF1. **Jangan diaktifkan lagi** kecuali instruktur memintanya: data stok hasil sinkron tetap tersimpan di database, dan jadwalnya dinilai dari export dan Executions yang sudah ada. Data sintetis berakhir di hari data terakhir, jadi digest harian isinya sama; jangan membiarkan sinkron dengan merchant yang selalu gagal mengirim alert tiap 15 menit selama berminggu-minggu.

## Jangan dikumpulkan

`.env`, API key (OpenAI atau lainnya), token asli (webhook, Kuma, penilaian, **token bot Telegram**), password database, email asli, data pribadi nyata, dan screenshot yang menampilkan nilai-nilai itu. Key OpenAI dari instruktur tidak di-commit dan tidak dibagikan ulang; hapus dari VPS saat terminate.

## Checklist sebelum push terakhir

Repo dan pengumpulan:

- [ ] Repo **public** di akun kalian; link sudah dikirim ke instruktur lewat DM
- [ ] Push terakhir ke `main` (paling lambat W4D4 23.59 WIB; disarankan selesai di W3D5 23.59)
- [ ] DM info akses penilai sudah terkirim ke instruktur (format di bawah)

Isi repo:

- [ ] `workflows/`: export JSON terbaru WF1-WF5 (WF5 = Error Workflow; chat Telegram WF3 boleh workflow terpisah)
- [ ] Export bersih: ID credential diganti placeholder, token push Kuma diganti `ISI_TOKEN_PUSH_KUMA` langsung di file export (jangan memakai `$env`), token bot Telegram dan key OpenAI tidak ada di file
- [ ] `docs/`: 01 BRD + process map, 02 desain + ROI, 03 TCO + deployment, 04 readiness checklist (status dan bukti per baris)
- [ ] `docs/05-readme-solusi.md`: diagram, cara menjalankan, cara memverifikasi (perintah macOS/Linux/Git Bash dan PowerShell 7)
- [ ] `.env.example` tanpa rahasia; `.env` tidak di-commit
- [ ] `evidence/wf1..wf5` dan `deploy` bernomor dan lengkap sesuai tabel Evidence di atas (Nilai penuh: bukti tambahan per folder bila dikerjakan)

Sebelum push terakhir:

- [ ] Kelima workflow **Published**; Error Workflow terpasang di WF1-WF4; sinkron stok sudah jalan sekali di instance VPS
- [ ] Production URL menjawab dari luar jaringan VPS; VPS dibiarkan hidup sampai instruktur memberi tahu penilaian selesai
- [ ] Bot Telegram mengirim digest, alert, dan approval (tombol di instance HTTPS, atau Wait node); bila chat asisten dikerjakan: asisten membalas dan chat kalian ada di allowlist
- [ ] Tidak ada secret di repo, export JSON, dan screenshot (daftar di bagian *Jangan dikumpulkan*)

## Format DM ke instruktur

Link repo sudah dikirim saat repo dibuat; DM ini berisi akses penilai, dikirim begitu selesai. Judul `Milestone P3 · <Nama>`. Jangan ditulis di repo atau channel publik.

| Item | Nilai |
| --- | --- |
| Base URL HTTPS instance (VPS) | https://... |
| Path webhook WF1 (`order.created`) | /webhook/... |
| Path webhook WF3 (asisten AI) | /webhook/... |
| Path webhook WF4 (`delivery.late`, `order.failed`) | /webhook/... |
| Token penilaian: nilai header `X-H8Mart-Token` di credential Header Auth webhook kalian (buat token baru khusus penilaian) | ... |
| Nama header jika bukan `X-H8Mart-Token` | |
| Username bot Telegram H8Mart Ops | @... |
| Chat asisten lewat Telegram | dikerjakan / tidak dikerjakan |

Setelah instruktur memberi tahu penilaian selesai: ganti token penilaian, hapus key OpenAI dari VPS, lalu terminate VPS.
