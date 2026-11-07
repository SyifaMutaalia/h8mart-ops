# Guide Milestone H8Mart

Folder ini berisi rincian yang dirujuk dari soal ([../README.md](../README.md)). Berkasnya disediakan dan **tidak diubah**; hasil kerja kalian tetap di `workflows/`, `docs/`, dan `evidence/`.

| Berkas | Isi | Dibuka saat |
| --- | --- | --- |
| [tasks.md](tasks.md) | Daftar tugas per 7 bagian penilaian (Minimum dan Nilai penuh) | sepanjang Milestone |
| [wf1-stock-sync-order-intake.md](wf1-stock-sync-order-intake.md) | WF1: sinkron stok, order masuk, digest | Peta Kerja tahap 1-2 |
| [wf2-merchant-data-tools.md](wf2-merchant-data-tools.md) | WF2: MCP Server | tahap 1 |
| [wf3-ai-merchant-assistant.md](wf3-ai-merchant-assistant.md) | WF3: asisten AI merchant | tahap 4 |
| [wf4-compensation-refund.md](wf4-compensation-refund.md) | WF4: voucher, refund, approval | tahap 2 dan 4 |
| [wf5-reliability-monitoring.md](wf5-reliability-monitoring.md) | WF5: Error Workflow, dead-letter, monitoring | tahap 1 dan 3 |
| [telegram-bot.md](telegram-bot.md) | empat touchpoint bot, aturan HTTPS, allowlist | sebelum digest, alert, approval |
| [common-mistakes.md](common-mistakes.md) | gejala, penyebab, solusi | saat macet |
| [submission.md](submission.md) | Evidence, checklist, format DM | sebelum push terakhir |

Setiap berkas `wf*` berisi **syarat** (Minimum dan Nilai penuh) lalu **diagram** susunannya.

## Cara membaca diagram

- Tiap kotak = satu node, dengan nama yang sama seperti di screenshot di bawahnya.
- Kotak tegas = susunan **Minimum**. **Kotak oranye bergaris putus** = tambahan nilai penuh atau jejak opsional. **Garis putus** = jalur gagal atau nilai penuh.
- Yang dinilai adalah syarat Minimum dan Nilai penuh, bukan jumlah kotak. Nama dan jumlah node kalian boleh berbeda selama Minimum terpenuhi.
- Screenshot = contoh canvas n8n 2.44.7 (versi nilai penuh). Klik untuk ukuran penuh.

Definisi cancel rate, SLA 30 menit, dan nominal refund ada di [data-contract.md](../data-contract.md) bagian 2.
