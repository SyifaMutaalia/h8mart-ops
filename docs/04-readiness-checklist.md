# 04 · Governance & Integration Readiness Checklist · H8Mart Quick-Commerce Ops

**Nama:** [isi nama peserta]  
**Status pengisian:** draf rancangan sebelum EC2 benar-benar berjalan. Baris yang belum diuji ditulis **Belum**, bukan Siap.

## 1. Credential & Akses

| Pemeriksaan | Status | Bukti |
| --- | --- | --- |
| Semua credential disimpan di n8n Credentials, bukan node/Code/repo | **Belum** | Verifikasi menu Credentials setelah setup EC2; jangan screenshot nilai secret |
| Role DB dipisah: `mcp_reader` dan `ops_writer` | **Belum** | File `seed/03-roles.sql`; nanti screenshot nama dua credential tanpa password |
| Webhook dilindungi Header Auth | **Belum** | Buat `X-H8Mart-Token`, uji request tanpa token harus 403 |
| `.env` tidak ada di repo; `.env.example` tanpa nilai nyata | **Siap pada paket** | `.gitignore` dan `.env.example` (jangan commit `.env` aktual) |
| Token push Kuma tidak ada di JSON export yang di-commit | **Belum** | Periksa WF1 dan ganti `ISI_TOKEN_PUSH_KUMA` sebelum commit |
| Bot Telegram token hanya di n8n Credentials | **Belum** | Isi credential setelah owner dibuat |
| Telegram chat allowlist `chat_id` → `merchant_id` | **Belum** | Query tabel `ops.telegram_merchants`, uji chat tidak dikenal ditolak |
| Akses ke instance n8n dibatasi | **Belum** | Screenshot security group 22 My IP, 80/443 publik, 5432/5678 tidak publik; autentikasi owner |

## 2. Kesiapan Sistem Existing

| Sistem | Cara terhubung | Rate limit / SLA yang diketahui | Perilaku bila down | Siapa dihubungi |
| --- | --- | --- | --- | --- |
| Merchant Stock API | `http://mock-api:8080/merchants/{id}/stock`, Header `X-Api-Key` | Tidak ditetapkan (Mock API latihan) | Retry terbatas; M009 permanen → dead-letter, M004 retry | Ops (simulasi) |
| Payment API | `http://mock-api:8080/payments/...`, Header `Idempotency-Key` + `X-Api-Key` | Tidak ditetapkan | Retry terbatas, `ops.dead_letter` bila gagal, jangan double refund | Finance/Ops (simulasi) |
| Notification (mock API) | `http://mock-api:8080/notify` | Tidak ditetapkan | Cek log error dan retry; alert Telegram cadangan | Ops |
| Telegram Bot API | Credential Telegram di n8n (HTTPS webhook untuk trigger) | Mengikuti provider Telegram (angka belum diuji) | Dead-letter atau alert alternatif; jangan hardcode token | Ops |
| PostgreSQL | host service `postgres:5432`, `mcp_reader`/`ops_writer` | SLA internal belum dinilai | Berhenti memproses event jika DB down, Error Workflow | Ops/infrastruktur |
| LLM provider | OpenAI API via credential (WF3) | Limit tergantung akun; belum terverifikasi | Fallback/eskalasi ke CS, jangan mengarang jawaban | Ops/CS |

## 3. Pra-Production

| Pemeriksaan | Status | Bukti |
| --- | --- | --- |
| Error Workflow terpasang di WF1–WF4 | **Belum** | `workflows/wf5-reliability-monitoring.json` starter; screenshot Settings WF1–WF4 setelah publish |
| Retry dan dead-letter diuji dengan kegagalan disengaja | **Belum** | `evidence/wf5/05-dead-letter.png` dan uji API M004/M009 |
| Heartbeat + sinkron 0 baris / digest kosong + ambang durasi | **Belum** | Uptime Kuma, API `/admin/stock-outage?on=1`, `/admin/slow-ms?ms=9000` |
| Data pelanggan tidak berlebihan di log/alert (masking) | **Belum** | Audit field business key saja, tidak ada email/telepon/customer_note |
| Rollback / Unpublish | **Belum** | Tes `Unpublish`, `docker compose down` tanpa `-v`, backup terverifikasi |
| Biaya token LLM dipantau | **Belum** | Dashboard usage OpenAI, catat model dan biaya real bila tersedia |

Tidak ada status operasional **Siap** sebelum bukti tersedia dari server AWS.
