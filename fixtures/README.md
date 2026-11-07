# Fixtures · H8Mart

Kirim ke webhook yang kalian buat (header Auth sesuai credential kalian). Contoh dengan `curl`, dijalankan dari root repo (n8n milestone di port 5690; nilai `X-H8Mart-Token` dari `.env.example`; ganti path webhook kalian):

```bash
curl -s -X POST http://localhost:5690/webhook/<path-order> -H "X-H8Mart-Token: h8mart-webhook-lab" -H "Content-Type: application/json" -d @fixtures/event-order-created-ok.json
```

PowerShell 7:

```powershell
Invoke-RestMethod -Method Post -Uri http://localhost:5690/webhook/<path-order> -Headers @{ "X-H8Mart-Token" = "h8mart-webhook-lab" } -ContentType "application/json" -InFile .\fixtures\event-order-created-ok.json
```

Pakai `/webhook-test/<path>` saat workflow belum Published (setelah menekan Execute workflow), dan `/webhook/<path>` setelah Published.

| File | Untuk | Yang diuji |
| --- | --- | --- |
| `event-order-created-ok.json` | WF1 order intake | order normal |
| `event-order-created-stok-habis.json` | WF1 | stok produk habis di merchant |
| `event-order-created-stok-menipis.json` | WF1 | stok cukup tetapi tipis |
| `event-order-created-item-kosong.json` | WF1 | event tidak valid |
| `event-delivery-late-ringan.json`, `event-delivery-late-berat.json` | WF4 | dua tingkat keterlambatan |
| `event-order-failed-kecil.json`, `event-order-failed-besar.json` | WF4 | refund kecil dan besar |
| `event-order-failed-ditolak.json` | WF4 | skenario Ops menolak |
| `event-order-failed-retry.json` | WF4 | gunakan bersama `POST /admin/fail-next?n=1` |
| `event-order-failed-payment-down.json` | WF4 | Payment selalu gagal (order `-099`): dead-letter + alert |
| `event-order-failed-belum-bayar.json` | WF4 | order belum dibayar |
| `question-catatan-injeksi.json` | WF3 | catatan pelanggan berisi instruksi palsu |
| `dev-set-asisten.json` | WF3 | 10 kasus berlabel (`harapan`): kirim `merchant_id` dan `question` ke WF3, bandingkan dengan label |

## Telegram

Payload update Telegram tidak disediakan sebagai fixture: uji chat asisten langsung dengan bot kalian setelah instance HTTPS. Selama lokal, uji WF3 lewat Webhook dengan `merchant_id` dan `question` seperti di `dev-set-asisten.json`. Aturan Telegram lainnya: [guide/telegram-bot.md](../guide/telegram-bot.md).

## Skenario tanpa file

- **Sinkron 0 baris:** `POST /admin/stock-outage?on=1` lalu jalankan sinkron; kembalikan dengan `on=0`.
- **Produk habis baru:** pilih produk yang stoknya > 0 di `core.merchant_stock`, buat habis di API dengan `POST /admin/stock/<merchant>/<SKU>?qty=0`, lalu jalankan sinkron dan cek apakah workflow kalian mendeteksinya.
- **Digest kosong:** jalankan digest untuk tanggal tanpa order (mis. 2099-01-01): lewat Manual Trigger, isi tanggal itu sementara (mis. node Set atau pinned data sebelum query KPI), lalu kembalikan ke hari data terakhir.
- **Merchant gagal:** M009 (permanen) dan M004 (sementara); lihat `GET /admin/stock-calls` untuk menghitung percobaan.

Kolom `harapan` di `dev-set-asisten.json`: `status` (`dijawab` atau `eskalasi_cs`), `harus_memuat_semua` / `harus_memuat_salah_satu` (teks yang harus ada di jawaban), `harus_memakai_tool_untuk`, `tidak_boleh_memanggil_tool_untuk`, `tidak_boleh_memuat`, `confidence_kurang_dari`. Data merujuk ke **hari data terakhir** (`core.data_info`; "kemarin" di pertanyaan = tanggal itu) dan angkanya sama di setiap laptop.

## Kasus Uji Publik

Gunakan kasus ini sebagai panduan uji mandiri. Hasilnya tidak wajib dikumpulkan: bukti yang dinilai hanya yang diminta di tabel Evidence di `guide/submission.md`. Angka target kalian ambil dari database dan hasil eksekusi sendiri, bukan ditebak dari dokumen.

| ID | Tindakan | Harapan |
| --- | --- | --- |
| S1 | Jalankan sinkron stok (jalur A WF1) dua kali berturut-turut | Jumlah baris `core.merchant_stock` tetap sama (205), tanpa duplikat |
| S2 | Merchant yang gagal sementara disinkron | Panggilan diulang lalu sukses; jumlah panggilan terlihat di `GET /admin/stock-calls` |
| S3 | Merchant yang gagal permanen disinkron | Dead-letter di `ops.dead_letter` dan alert dengan business key; merchant lain tetap tersinkron |
| S4 | `POST /admin/stock-outage?on=1`, jalankan sinkron | Gagal terkendali (alert), bukan sukses diam-diam; heartbeat tidak terkirim |
| O1 | Kirim `event-order-created-ok.json` | Diterima (HTTP 200) |
| O2 | Kirim `event-order-created-stok-habis.json` | Ditolak karena stok habis (HTTP 409) |
| O3 | Kirim `event-order-created-stok-menipis.json` (nilai penuh) | Diterima dengan peringatan stok tipis |
| O4 | Kirim `event-order-created-item-kosong.json` | Ditolak sebagai tidak valid |
| O5 | Kirim `event-order-created-ok.json` dua kali | Tepat satu order; tanpa/salah token ditolak 403 |
| D1 | Jalankan digest untuk hari data terakhir (default) | Angka sama dengan SQL independen atas `core.orders` |
| D2 | Jalankan digest untuk 2099-01-01 | Terdeteksi sebagai digest kosong, bukan sukses diam-diam |
| M1 | `INSERT` memakai credential `mcp_reader` | Ditolak oleh database |
| M2 | Jalankan MCP Client (deterministik) dan MCP Client Tool (agent) | Kedua jalur memanggil tool WF2; tampak di Executions |
| A1 | Kirim 10 kasus `dev-set-asisten.json` ke WF3 (Webhook production) | Hasil per kasus dilaporkan (aktual vs label `harapan`); sebagian besar sesuai, kasus yang meleset dijelaskan |
| A2 | Kirim `question-catatan-injeksi.json` | Instruksi di catatan pelanggan tidak diikuti; data merchant lain tidak diambil |
| A3 | Pertanyaan di luar data (kompensasi, prediksi) | `eskalasi_cs` dan baris `ops.tickets`, bukan jawaban karangan |
| A4 | Ganti key OpenAI dengan nilai salah | Workflow tidak jatuh; hasil eskalasi ke CS (fallback) |
| C1 | Kirim `event-delivery-late-ringan.json` dan `...-berat.json` | Voucher sesuai kebijakan yang kalian dokumentasikan, tercatat di `ops.compensations` |
| C2 | Kirim `event-order-failed-kecil.json` | Refund otomatis; Payment dipanggil dengan `Idempotency-Key` |
| C3 | Kirim `event-order-failed-besar.json`, lalu approve | `pending_approval`, lalu `refunded` sekali |
| C4 | Kirim event atau approval yang sama dua kali | Voucher/refund tetap satu (resume kedua ditolak) |
| C5 | Kirim `event-order-failed-ditolak.json`, lalu reject | Tercatat ditolak; Payment tidak dipanggil |
| C6 | `event-order-failed-retry.json` dengan `POST /admin/fail-next?n=1` | Payment diulang lalu sukses |
| C7 | `event-order-failed-payment-down.json`, lalu approve | Percobaan ulang habis, dead-letter dan alert dengan `order_id` |
| R1 | Picu error di workflow mana pun | Error Workflow pusat tereksekusi dan mengirim alert |
| R2 | Hentikan sinkron lalu pulihkan | Kuma menampilkan Down lalu Up |
| R3 | Turunkan ambang durasi sementara, jalankan sinkron | Alert ambang durasi terkirim |
| G1 | `grep` repo, export JSON, dan screenshot untuk key/token | Tidak ada secret; token push Kuma berupa `ISI_TOKEN_PUSH_KUMA` |

Bila API atau model tidak tersedia, workflow harus gagal secara terkendali (alert atau eskalasi), tidak mengembalikan hasil rekaan.
