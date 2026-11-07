# Kesalahan Umum

[Guide](README.md) · [Soal bagian 3](../README.md#3-sistem-yang-harus-dibangun)

Gejala yang paling sering menghambat, beserta penyebab dan solusinya. Cek di sini sebelum bertanya.

| Gejala | Penyebab | Solusi |
| --- | --- | --- |
| Node HTTP atau Postgres gagal tersambung | Di dalam container n8n, `localhost` adalah container n8n sendiri | Pakai nama service (`postgres`, `mock-api`, `uptime-kuma`, `n8n`), lihat `SETUP.md` |
| Merchant yang gagal tidak diulang | **Retry On Fail memutuskan dari item pertama**: bila satu node HTTP menerima banyak item sekaligus dan memakai error output, item lain yang gagal tidak diulang | Proses tiap merchant satu per satu ([Loop Over Items](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.splitinbatches/), batch size 1; hanya disinggung di Bacaan Mandiri S05, baca docs-nya), lalu buktikan retry lewat `GET /admin/stock-calls` |
| Eksekusi hijau, tetapi langkah sesudah loop tidak jalan | **Loop Over Items berhenti diam-diam** bila salah satu cabang di dalam loop (termasuk error output) tidak disambung kembali ke loop | Sambungkan semua cabang ke loop; cek jumlah item di tiap node, bukan hanya warna hijau |
| Tombol approval Telegram ditolak (`Wrong HTTP URL`) | Resume URL mengarah ke `localhost` | Pakai Wait node selama lokal; tombol setelah VPS HTTPS hidup ([telegram-bot.md](telegram-bot.md#menguji-approval-selama-lokal-wait-node)) |
| Pesan Telegram ditolak (`can't parse entities`) | Karakter `_` atau `*` di teks Markdown (mis. `order_id`) | Hindari karakter itu atau pakai Parse Mode `HTML` ([aturan](telegram-bot.md#aturan)) |
| Telegram Trigger tidak menerima pesan | Satu bot hanya punya satu webhook | Pakai bot kedua untuk uji ([aturan](telegram-bot.md#aturan)) |
| Angka digest atau jawaban asisten berbeda dari harapan | "Kemarin" dihitung dari jam sistem | Pakai **hari data terakhir** dari `core.data_info` ([soal bagian 3](../README.md#3-sistem-yang-harus-dibangun)) |
