# workflows/

Taruh export JSON **terbaru** WF1-WF5 di folder ini, satu file per workflow (WF5 = Error Workflow; chat Telegram WF3 boleh workflow terpisah).

| File | Workflow |
| --- | --- |
| `wf1-<nama>.json` | WF1 Stock Sync, Order Intake dan Digest |
| `wf2-<nama>.json` | WF2 Merchant Data Tools (MCP Server) |
| `wf3-<nama>.json` | WF3 Asisten AI Merchant |
| `wf3b-<nama>.json` | Chat asisten lewat Telegram, bila dibuat sebagai workflow terpisah (ikut di-Publish; evidence di `evidence/wf3/`) |
| `wf4-<nama>.json` | WF4 Kompensasi dan Refund |
| `wf5-<nama>.json` | WF5 Reliability dan Monitoring |

Sebelum commit, cek file export:

- [ ] ID credential di export diganti `GANTI-ID-<nama>` (mis. `GANTI-ID-PG-OPS`)
- [ ] Token push Uptime Kuma diganti `ISI_TOKEN_PUSH_KUMA` langsung di file (jangan memakai `$env`)
- [ ] Token bot Telegram dan key OpenAI tidak ada di file

Daftar periksa lengkap sebelum push terakhir: [guide/submission.md](../guide/submission.md#checklist-sebelum-push-terakhir).
