# Daftar bukti yang harus diambil dari AWS (belum terverifikasi)

- [ ] `deploy/01-ec2-running.png` EC2 Running region Jakarta, jenis instance, SG; tutupi account ID jika tampil.
- [ ] `deploy/02-compose-ps.png` 6 container running, PostgreSQL healthy.
- [ ] `deploy/03-https-owner.png` browser URL HTTPS n8n.
- [ ] `deploy/04-webhook-success.png` request Production URL 200 dan 409, tanpa membocorkan token.
- [ ] `deploy/05-persistence.png` restart & workflow tetap ada.
- [ ] `wf1/01-canvas-published.png`, `wf1/02-executions.png`, `wf1/03-stock-sql.png`, `wf1/04-order-200-409.png`, `wf1/05-digest-telegram.png`.
- [ ] `wf2/01-canvas-published.png`, `wf2/02-executions.png`, `wf2/03-mcp-tool-agent.png`.
- [ ] `wf3/01-canvas-published.png`, `wf3/02-executions.png`, `wf3/03-jawaban-ai.png`, `wf3/04-eskalasi-fallback.png`.
- [ ] `wf4/01-canvas-published.png`, `wf4/02-executions.png`, `wf4/03-approval.png`, `wf4/04-refund-idempotent.png`.
- [ ] `wf5/01-error-source.png`, `wf5/02-error-workflow.png`, `wf5/03-alert-telegram.png`, `wf5/04-log-rutin.png`, `wf5/05-dead-letter.png`, `wf5/06-silent-failure.png`, `wf5/07-durasi-alert.png`, `wf5/08-kuma-up-down.png`.
- [ ] `docs/03-tco-deployment.md` perhitungan biaya + sumber + 4 bagian seperti set_1.
- [ ] `docs/06-rekomendasi-tco-day3.md` 5 bagian template Day 3.

Tidak ada screenshot palsu di paket. Ambil dari EC2 dan aplikasi milikmu yang berjalan. **Jangan push secrets**.
