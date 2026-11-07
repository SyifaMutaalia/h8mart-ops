# Tugas per Bagian Penilaian

[Guide](README.md) · [Soal](../README.md) · [Poin per bagian](../README.md#6-penilaian)

Tiap tugas masuk ke salah satu dari 7 bagian penilaian, dan **tidak ada tugas wajib di luar yang tertulis di sini**. Ada dua tingkat: **Minimum** (cukup untuk Meet Expectations) dan **Nilai penuh** (tambahan). Kerjakan Minimum dulu. Bukti eksekusi (Executions, baris database, chat Telegram di HP) mengalahkan node yang hanya terpasang. Syarat Minimum dan Nilai penuh tiap workflow ada di file WF masing-masing; bukti per folder di [submission.md](submission.md#evidence).

## Business Requirement & Solution Design

- **BRD dan process map** (bukti: `docs/01-brd-process-map.md`):
  - BRD dengan minimal 3 masalah bisnis **bersumber** (potongan cerita skenario atau data seed).
  - Process map **as-is** dan **to-be** yang berbeda. To-be memuat **titik manusia** (approval Ops di Telegram, eskalasi ke CS) dan **titik AI** (WF3), minimal dua decision point, dan satu jalur exception.
  - Tabel translasi langkah manual ke node atau workflow **dengan alasan**.
- **Keputusan otomasi dan ROI** (bukti: `docs/02-desain-solusi-roi.md`):
  - Minimal 5 keputusan (mis. stok cukup atau habis, besar voucher dan refund, jawab atau eskalasi merchant, urutan alert), masing-masing diberi pendekatan rule-based, AI, atau manusia **dengan alasan**.
  - ROI punya rumus, asumsi, biaya LLM, dan risiko. Nilai penuh: biaya LLM dihitung dari **token eksekusi kalian sendiri**.

## n8n Workflow Build

- **Trigger dan konfigurasi:** WF1-WF5 end-to-end dengan trigger sesuai peran (Schedule, Webhook dengan Header Auth, MCP Server Trigger, Error Trigger). Antar-container pakai nama service (`postgres`, `mock-api`), bukan `localhost`; tanpa credential di parameter node; kelima workflow **Published**. Bukti: `workflows/*.json`.
- **Pengolahan data:** normalisasi (Code node), **Merge** dengan katalog produk, **upsert idempotent**, dan **If/Switch** stok di jalur order. Syarat: [WF1](wf1-stock-sync-order-intake.md).
- **Jadwal dan event:** Schedule 15 menit (sinkron) dan 07.00 (digest) dengan **Timezone `Asia/Jakarta`** (menu **⋯** › **Settings** › **Timezone**, jangan dibiarkan `Default`, supaya tersimpan di export); Webhook `order.created`, `delivery.late`, `order.failed` dengan Header Auth. Nilai penuh: chat merchant lewat Telegram Trigger ([WF3](wf3-ai-merchant-assistant.md)).

## System Integration & MCP

- **Integrasi eksternal:** PostgreSQL dengan role tepat (`ops_writer` untuk menulis `ops.*`), Merchant Stock API, **Payment API dengan `Idempotency-Key`**, Notification API, webhook, dan approval Ops lewat Telegram; error HTTP ditangani. Syarat: [WF1](wf1-stock-sync-order-intake.md), [WF4](wf4-compensation-refund.md), [bot Telegram](telegram-bot.md).
- **MCP Server dan agent tools:** tiga tool read-only dengan credential `mcp_reader`, dipanggil agent WF3. Syarat: [WF2](wf2-merchant-data-tools.md).

## AI on Automation

- **Asisten AI:** agent `gpt-6-luna` dengan output terstruktur, guardrail eskalasi ke CS, fallback, dan Webhook production Published (path dikirim lewat DM). Syarat: [WF3](wf3-ai-merchant-assistant.md).

## Reliability & Monitoring

- **Error handling dan monitoring:** empat mekanisme error handling (retry on fail, dead-letter, alerting ke Telegram, Error Workflow pusat) dan monitoring (heartbeat Uptime Kuma, satu deteksi kegagalan diam-diam, satu alert perlambatan) termasuk **Minimum**. Syarat dan tabel bukti: [WF5](wf5-reliability-monitoring.md#bukti-empat-mekanisme-error-handling).

## Deployment, Cost & Governance

- **Instance self-hosted di VPS** (bukti: `evidence/deploy/`):
  - Kelima workflow **Published** di n8n self-hosted (VPS AWS, Docker Compose, Caddy HTTPS, `.env`); panduan: `SETUP.md` bagian 7.
  - **Satu VPS**, dibuat setelah lab S09 (paling lambat W4D2) dan **dibiarkan hidup sampai instruktur memberi tahu lewat DM bahwa penilaian selesai** (penilai memanggil Production URL), lalu di-terminate.
  - Database n8n cukup SQLite bawaan (volume `n8n_data`; catat di `docs/03-tco-deployment.md`, baris *Database n8n*). PostgreSQL di stack hanya untuk data H8Mart.
- **Perbandingan biaya (TCO)** (bukti: `docs/03-tco-deployment.md`): tiga opsi (mis. n8n Cloud, self-hosted VPS, on-premise) dengan biaya 12 bulan **berumus**, **tanggal dan sumber** harga, satu syarat kepatuhan (hanya pasal yang benar-benar kalian baca), keputusan dan alasan.
- **Credential, akses, dan readiness** (bukti: `docs/04-readiness-checklist.md`, bagian akses dan placeholder di `workflows/`):
  - Credential hanya di n8n dan `.env` yang di-ignore git; token bot Telegram dan key OpenAI hanya di credential n8n, tidak ada di export; tidak ada secret di repo, export, dan screenshot.
  - Role database terpisah (`mcp_reader` read-only, `ops_writer`).
  - Akses dibatasi: Header Auth webhook, endpoint MCP tidak dibuka ke internet oleh `Caddyfile` bawaan, Security Group VPS, allowlist `chat_id` bila chat asisten dikerjakan.
  - Checklist pra-production dengan **bukti per baris**, termasuk kesiapan Merchant Stock API dan Payment (rate limit, perilaku saat down).

## Workflow Quality & Documentation

- Workflow berjalan end-to-end dengan fixture; nama node deskriptif (bukan `HTTP Request1`); sticky note per bagian alur; README solusi berisi diagram, cara menjalankan, dan cara memverifikasi. Bukti: `workflows/`, `docs/05-readme-solusi.md`, `evidence/wf1..wf5/` bernomor.
