# Data Contract · H8Mart Quick-Commerce Ops

Kontrak data, event, dan API untuk Milestone 3. Semua data sintetis. Contoh memakai port bawaan `.env.example`; dari dalam container n8n pakai nama service (lihat `SETUP.md`).

## 1. Koneksi

| Sistem | Dari laptop | Dari dalam n8n |
| --- | --- | --- |
| PostgreSQL `h8mart` | `localhost:5440` | host `postgres`, port `5432` |
| Mock API | `http://localhost:8080` | `http://mock-api:8080` |
| Uptime Kuma | `http://localhost:3011` | `http://uptime-kuma:3001` |
| n8n | `http://localhost:5690` | `http://n8n:5678` (mis. endpoint MCP `http://n8n:5678/mcp/<path>`) |

Role database (password di `.env.example`, hanya untuk latihan):

| Role | Hak | Dipakai untuk |
| --- | --- | --- |
| `mcp_reader` | SELECT `core.*` dan `ops.*`, sesi read-only | WF2 (tool MCP), query baca |
| `ops_writer` | SELECT `core.*`; INSERT/UPDATE `core.merchant_stock`; INSERT `core.orders` dan `core.order_items`; INSERT/UPDATE `ops.*` | WF1, WF4, WF5 (menulis); WF3 hanya untuk menulis tiket `ops.tickets` |
| `h8mart` | superuser | hanya untuk kalian di laptop atau lewat `docker compose exec` (reset, query bebas), **jangan** dipakai sebagai credential n8n |

WF3 memakai **dua credential**: `mcp_reader` untuk membaca (tool MCP, `core.data_info`, allowlist `ops.telegram_merchants`) dan `ops_writer` untuk `INSERT` ke `ops.tickets`.

## 2. Skema `core.*` (data H8Mart)

Data 90 hari. **Hari data terakhir** = hari seed dijalankan (zona WIB) dikurangi 1, tersimpan di `core.data_info.hari_data_terakhir`. **Semua "kemarin" dan "hari ini" dalam soal, digest, tool MCP, dan pertanyaan merchant merujuk ke tanggal itu**, bukan ke jam sistem, sehingga angkanya tetap sama kapan pun dikerjakan.

| Tabel | Kolom penting | Catatan |
| --- | --- | --- |
| `core.merchants` | `merchant_id` (M001-M012), `name`, `zone`, `merchant_type`, `active` | zona: Jakarta Selatan, Tangerang, Bekasi |
| `core.products` | `product_id` (P001-P030), `sku` (SKU-001-SKU-030), `name`, `category`, `price` | katalog dipakai semua merchant |
| `core.data_info` | `hari_data_terakhir` (satu baris) | tanggal data terakhir; rujukan semua "kemarin" |
| `core.merchant_stock` | `merchant_id`, `product_id`, `qty`, `synced_at` (PK gabungan) | 205 baris. Diisi dari Merchant Stock API; nilai awal **basi 6 jam** |
| `core.customers` | `customer_id`, `zone` | 800 pelanggan |
| `core.orders` | `order_id`, `customer_id`, `merchant_id`, `zone`, `order_date`, `created_at`, `status`, `cancel_reason`, `total_amount`, `payment_status`, `customer_note` | `status`: `active`, `delivered`, `cancelled`, `failed`. `payment_status`: `captured`, `unpaid`, `refunded`. `customer_note` adalah teks bebas pelanggan |
| `core.order_items` | `order_id`, `product_id`, `qty`, `unit_price` | |
| `core.couriers` | `courier_id`, `zone` | 6 kurir |
| `core.deliveries` | `order_id`, `courier_id`, `promised_minutes` (30), `actual_minutes`, `delivered_at` | hanya order `delivered`. Tepat waktu: `actual_minutes <= promised_minutes` |

`cancel_reason`: `stok_habis`, `pelanggan_membatalkan`, `merchant_menolak`, `kurir_tidak_ada`, `pembayaran_gagal`.

**Definisi:** `total_amount` = Σ (`qty` × `unit_price`) + ongkir Rp8.000 (berlaku untuk semua order, termasuk order kasus uji). **Nominal refund = `core.orders.total_amount`** order itu. **Cancel rate** = (order `cancelled` + `failed`) ÷ semua order pada `order_date` itu. **SLA 30 menit** = order `delivered` dengan `actual_minutes <= promised_minutes` ÷ semua order `delivered` pada tanggal itu.

Order `HM-SP-xxx` adalah **order kasus uji** (status `active` atau `failed`, tanggal hari data terakhir, merchant M001, `customer_id` C0001) yang dipakai fixture event `delivery.late` dan `order.failed`; beberapa tidak ada di fixture (disimpan penilai). Mereka ikut terhitung di tabel `core.orders`.

## 3. Skema `ops.*` (ditulis workflow kalian)

| Tabel | Fungsi | Kolom penting |
| --- | --- | --- |
| `ops.sync_runs` | satu baris per run sinkron stok | `run_at`, `merchants_total`, `merchants_ok`, `rows_synced`, `new_stockouts`, `duration_ms` |
| `ops.dead_letter` | kegagalan yang tidak pulih | `workflow`, `node`, `execution_id`, `business_key`, `error_message`, `payload` (jsonb), `attempts`, `status` (`open`/`replayed`/`discarded`) |
| `ops.compensations` | voucher kompensasi | `order_id`, `kind`, `amount`, `idempotency_key` (unik), `status` (`pending`/`issued`/`failed`), `payment_ref` |
| `ops.refund_actions` | usulan dan hasil refund | `order_id`, `idempotency_key` (unik), `amount`, `status` (`pending_approval`/`approved`/`refunded`/`rejected`/`failed`), `approved_by`, `payment_ref` |
| `ops.tickets` | eskalasi ke CS | `merchant_id`, `question`, `ai_answer`, `reason`, `status` |
| `ops.telegram_merchants` | allowlist chat Telegram ke merchant (kosong; kalian isi dengan `chat_id` sendiri) | `chat_id` (bigint, kunci), `merchant_id`, `label` |

Seed bisa dijalankan ulang (mengembalikan semua data dan `ops.*` ke keadaan awal): lihat `SETUP.md`.

## 4. Mock API

Semua endpoint (kecuali `/health`) wajib header `X-Api-Key: <MOCK_API_KEY>`. Salah/kosong = `401`. State di memori: restart container = reset.

### 4.1 Merchant Stock API

```text
GET /merchants/{merchant_id}/stock
```

Respons `200`:

```json
{
  "merchant_id": "M001",
  "as_of": "2026-01-01T08:00:00.000Z",
  "items": [
    { "sku": "sku-001", "qty": "7" },
    { "sku": "sku-004", "qty": "6" }
  ]
}
```

Perhatikan: `sku` huruf kecil dan `qty` berupa **string**; kalian yang menormalkannya. Perilaku merchant (sengaja, untuk menguji ketahanan):

| Merchant | Perilaku |
| --- | --- |
| M004 | `500` pada panggilan ganjil, `200` pada panggilan genap (gagal sementara) |
| M007 | selalu lambat (±2,5 detik) |
| M009 | selalu `500` (gagal permanen) |
| lainnya | normal |

Merchant tidak dikenal: `404`. Mode kegagalan diam-diam: lihat `/admin/stock-outage` (semua merchant menjawab `200` dengan `items` kosong).

### 4.2 Payment API

```text
POST /payments/refunds
POST /payments/vouchers
Header: Idempotency-Key: <kunci unik per tindakan>
Body:   { "order_id": "HM-SP-003", "amount": 80000 }
```

| Kasus | Respons |
| --- | --- |
| Pertama kali | `201` `{ "refund_id": "RF-00001", "order_id": "...", "amount": 80000, "status": "succeeded", "replayed": false }` (voucher: `voucher_id` `VC-...`) |
| `Idempotency-Key` sama | `200` dengan hasil lama dan `"replayed": true` (tidak diproses ulang) |
| Header `Idempotency-Key` kosong | `400` `idempotency_key_required` |
| `amount` bukan angka positif | `422` |
| Gateway gangguan | `503` `payment_gateway_unavailable`. Order berakhiran `-099` **selalu** gagal |

`GET /payments/refunds` dan `GET /payments/vouchers` menampilkan semua yang tercatat (`count`, daftar, dan `calls` = jumlah panggilan ke Payment, refund dan voucher dihitung bersama).

### 4.3 Notification API

```text
POST /notify          { "channel": "ops-alerts", "title": "...", "text": "..." }   -> 201
GET  /notify/messages ?channel=ops-alerts                                          -> 200 { "count": n, "messages": [...] }   (count = jumlah hasil setelah filter)
```

Kanal bebas. Notification API tetap dipakai sebagai jejak yang bisa dicek (selain bot Telegram, lihat `guide/telegram-bot.md`). Saran: `ops-digest`, `ops-alerts`, `ops-approval`, `merchant-ops`, `cs-eskalasi`, `push` (ke pelanggan). Kanal peserta sendiri (mis. webhook Discord) boleh dipakai selain mock ini.

### 4.4 Endpoint admin (uji kegagalan, bukan bagian produksi)

| Endpoint | Fungsi |
| --- | --- |
| `POST /admin/fail-next?n=1` | `n` panggilan Payment berikutnya dijawab `503` |
| `POST /admin/stock-outage?on=1` / `on=0` | semua merchant menjawab `200` tanpa item / kembali normal |
| `POST /admin/slow-ms?ms=9000` | atur latensi M007 |
| `POST /admin/stock/M001/SKU-001?qty=0` | ubah stok yang dikembalikan API untuk satu merchant dan SKU |
| `POST /admin/delay-notify?ms=5000` | tunda jawaban Notification |
| `GET /admin/stock-calls` | jumlah panggilan stok per merchant (bukti retry) |
| `POST /admin/reset` | reset semua state mock |

## 5. Event

Semua event dikirim sebagai `POST` JSON ke webhook yang kalian buat (dilindungi Header Auth, nama header dan nilai bebas; nilai contoh `.env.example`: `X-H8Mart-Token`).

### `order.created`

```json
{ "event": "order.created", "order_id": "HM-TEST-001", "customer_id": "C0100", "merchant_id": "M001", "total_amount": 80000,
  "customer_note": "Tolong titip ke satpam.", "items": [ { "sku": "SKU-001", "qty": 1 } ] }
```

### `delivery.late`

```json
{ "event": "delivery.late", "order_id": "HM-SP-001", "minutes_late": 12 }
```

### `order.failed`

```json
{ "event": "order.failed", "order_id": "HM-SP-003", "reason": "kurir_tidak_ada" }
```

`order.failed` berarti order tidak bisa dipenuhi; bila pembayaran sudah tertagih (`payment_status = captured`), uang pelanggan harus dikembalikan.

### Pertanyaan merchant (WF3): kontrak Webhook production

WF3 **wajib Published** dan membalas **sinkron** (node Respond to Webhook). Penilai memanggilnya lewat Production URL (path dari DM kalian ke instruktur, header Header Auth `X-H8Mart-Token`).

```json
{ "merchant_id": "M003", "question": "Kenapa order saya banyak batal kemarin?" }
```

Balasan: HTTP **200**, JSON:

| Field | Isi |
| --- | --- |
| `status` | `dijawab` atau `eskalasi_cs` |
| `jawaban` | teks untuk merchant (bila `eskalasi_cs`: pemberitahuan bahwa pertanyaan diteruskan ke CS) |
| `data_dipakai` | daftar sumber data yang dipakai (array) |
| `confidence` | angka 0 sampai 1 |
| `alasan` | alasan eskalasi (hanya bila `eskalasi_cs`) |

Telegram Trigger adalah tambahan: ia memakai logika yang sama (memanggil Webhook ini atau berbagi node) dan **bukan pengganti** Webhook.

### Pesan Telegram (WF3 lewat chat)

Telegram Trigger mengirim update Telegram ke workflow. Bagian yang dipakai: `message.chat.id` (angka, kunci allowlist `ops.telegram_merchants`), `message.text` (pertanyaan), dan `message.from.id`. `merchant_id` **tidak pernah** diambil dari teks pesan, hanya dari allowlist. Kontrak jawaban WF3 sama dengan webhook di atas; balasan dikirim ke chat dengan Send Message.

## 6. Fixtures

Lihat `fixtures/README.md`. Dev set asisten AI: `fixtures/dev-set-asisten.json` (10 kasus berlabel).

## 7. Uptime Kuma

Buat monitor tipe **Push**, salin URL push (`http://uptime-kuma:3001/api/push/<token>?status=up&msg=OK&ping=`) ke node HTTP Request di workflow. Interval monitor diset **lebih besar dari interval jadwal** yang dimonitor (mis. sinkron 15 menit, monitor 20 menit). Token adalah rahasia: **ganti dengan `ISI_TOKEN_PUSH_KUMA` di file export sebelum commit**.
