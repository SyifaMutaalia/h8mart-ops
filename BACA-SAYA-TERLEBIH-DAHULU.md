# Milestone 3 H8Mart — versi AWS EC2 langsung

**Isi folder ini berasal dari `milestone_phase3_set1-main/set_1` asli, tidak digantikan oleh tiga praktikum lain.** File root `README.md`, `SETUP.md`, `compose.yaml`, `compose.vps.yaml`, `Caddyfile`, data seed, Mock API, fixtures dan guide instruktur tidak dihapus.

## Tambahan pada proyek

| File | Fungsi |
| --- | --- |
| `MULAI-DI-AWS-EC2.md` | Alur kerja dari membuat instance AWS EC2, instal Docker di EC2, clone repo, hingga jalankan stack. |
| `docs/03-tco-deployment.md` | Template **4 bagian asli set_1** telah diisi simulasi H8Mart menggunakan rumus/tabel Day 3. Bukti harus dilengkapi setelah AWS berjalan. |
| `docs/06-rekomendasi-tco-day3.md` | Template **5 bagian Day 3** tersendiri, kasus H8Mart. Tidak menggantikan `03`. |
| `docs/07-alerting-dan-log-day5.md` | Adaptasi pusat alert berseverity dan dua jenis log, mengikuti pola Day 5. |
| `workflows/wf5-reliability-monitoring.json` | Starter WF5 untuk di-import di n8n EC2; wajib disetel credentials dan diuji, **belum mencakup seluruh mekanisme WF5**. |
| `tambahan/day3/kalkulator-tco-h8mart.json` | Workflow perhitungan TCO opsional; bukan WF1–WF5, belum diuji. |
| `evidence/CEKLIST-BUKTI-AWS.md` | Checklist bukti untuk Jumat–Senin. |
| `aws-ec2/bootstrap-ubuntu.sh` | Instal Docker dan swap di EC2 (opsional saat User Data). |
| `referensi-instruktur/day3..day5/` | Salinan README asli untuk rujukan, tidak perlu deploy stack latihan terpisah. |

## Status nyata

- **Sudah disiapkan:** repositori set_1 terstruktur, dokumen TCO 03 dan 06, WF5 JSON starter, dokumentasi alert/log, panduan AWS.
- **Belum dilakukan:** menjalankan EC2 dalam akun milik peserta, mengonfigurasi domain/kredensial, membangun WF1–WF4, uji end-to-end, dan mengambil screenshot bukti. Tidak ada klaim lulus atau berhasil deploy sebelum uji nyata.
- **Urutan kerja setelah EC2 hidup:** WF5 → WF2 → WF1 → WF3 → WF4. Baca panduan `guide/` dan cek file `MULAI-DI-AWS-EC2.md`.

**Peringatan privasi & biaya:** jangan commit `.env`, password, token Telegram/OpenAI, atau screenshot berisi secrets. Akun Free Tier tergantung tanggal pendaftaran dan kredit tersisa. Jangan menutup EC2 sampai smoke test penilai selesai.
