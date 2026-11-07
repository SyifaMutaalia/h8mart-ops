# Bot Telegram H8Mart Ops

[Guide](README.md) · [Soal bagian 3](../README.md#3-sistem-yang-harus-dibangun)

Tiap peserta membuat **satu bot** lewat **@BotFather** (gratis) dan menyambungkannya ke n8n dengan credential **Telegram API**. Token dari BotFather **tidak pernah** masuk repo, `.env`, atau export; hanya ada di credential n8n. Langkah membuat bot dan mengambil `chat_id`: [SETUP.md bagian 5b](../SETUP.md#5b-bot-telegram-h8mart-ops).

## Empat touchpoint

| # | Touchpoint | Node Telegram | Workflow | Bisa dikerjakan |
| --- | --- | --- | --- | --- |
| 1 | **Digest pagi** (order, cancel rate, SLA; nilai penuh: alasan batal teratas dari MCP), format rapi | Send Message | WF1 | lokal, setelah WF1 (W2D2) |
| 2 | **Alert** Error Workflow (workflow, node, waktu, `order_id` atau `merchant_id`); alert kegagalan diam-diam dan durasi memakai jalur yang sama | Send Message | WF5 | lokal, sejak W2D1 |
| 3 | **Approval Ops** untuk refund di atas ambang: pesan dengan tombol Approve/Decline | Send and Wait for Response (Response Type `Approval`, Type of Approval `Approve and Disapprove`) | WF4 | **setelah VPS HTTPS hidup** (W2D4/W2D5); selama lokal pakai [Wait node](#menguji-approval-selama-lokal-wait-node) |
| 4 | **Chat asisten merchant** (nilai penuh): merchant bertanya lewat chat, WF3 menjawab | Telegram Trigger (+ Send Message untuk balasan) | WF3 (Webhook WF3 tetap jalur utama) | setelah VPS HTTPS hidup; selama lokal, uji lewat Webhook (kontrak sama) |

## Aturan

- **Mengirim pesan biasa tidak butuh HTTPS**, jadi digest dan alert bisa jalan dari laptop. **Tombol approval butuh instance HTTPS publik**: tombol Send and Wait berisi resume URL n8n, dan Telegram menolak URL `localhost` (node gagal dengan `Bad Request: inline keyboard button URL ... is invalid: Wrong HTTP URL`). **Telegram Trigger untuk chat asisten juga butuh webhook HTTPS publik** (instance setelah W2D4).
- **Satu bot hanya punya satu webhook:** Test URL dan Production URL saling menimpa. Pakai **bot kedua** untuk uji, atau unpublish workflow bila memakai Test URL.
- **Format pesan:** node Telegram memakai Markdown secara bawaan, jadi karakter `_` dan `*` di teks (mis. `order_id`) dapat membuat Telegram menolak pesan (`can't parse entities`). Tulis teks tanpa karakter itu atau, di Send Message, pilih Parse Mode `HTML`. **Send and Wait for Response selalu memakai Markdown** (tidak ada pilihan Parse Mode), jadi pesan approval harus bebas `_` dan `*`.
- **Allowlist `chat_id` (wajib bila chat asisten dikerjakan):** isi `ops.telegram_merchants` (`chat_id`, `merchant_id`) dengan chat kalian sendiri, dipetakan ke satu merchant pilihan kalian (mis. `M003`); perintah pengisiannya ada di [SETUP.md bagian 5b](../SETUP.md#5b-bot-telegram-h8mart-ops). `merchant_id` selalu diambil dari tabel itu, **bukan** dari teks pesan; chat yang tidak terdaftar dijawab sopan bahwa akunnya belum terdaftar dan **tidak** diteruskan ke agent.
- Mock Notification API tetap dipakai untuk notifikasi pelanggan dan merchant dan sebagai jejak yang bisa dicek penilai; digest dan alert boleh dikirim ke keduanya.

## Menguji approval selama lokal (Wait node)

Telegram menolak tombol ber-URL `localhost`, jadi selama lokal pakai **Wait node** (Resume `On Webhook Call`): kirim resume URL-nya (`{{ $execution.resumeUrl }}`) sebagai teks biasa lewat Send Message, lalu buka di browser laptop dengan keputusan di parameter query (mis. `?keputusan=approve`). Setelah HTTPS, tombol bisa dibuka dari HP, dan opsi **Approve Within Chat** memberi persetujuan satu ketukan di dalam chat.
