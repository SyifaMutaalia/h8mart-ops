# Rekomendasi Strategi Deployment n8n

| | |
| --- | --- |
| Disusun untuk | H8Mart Quick-Commerce Ops (studi kasus milestone) |
| Disusun oleh | [Nama peserta], Automation Engineer |
| Tanggal | 7 November 2026 |
| Sumber angka | Simulasi rumus pada `docs/03-tco-deployment.md` dengan parameter Day 3: **35.000 eksekusi/bulan** dan tarif SDM **USD 15/jam**. Workflow kalkulator tersedia sebagai bahan demonstrasi di `referensi-instruktur/day3/` dan `tambahan/day3/`; eksekusi n8n belum diverifikasi. |

## 1. Rekomendasi (satu kalimat)

**Self-hosted n8n di AWS EC2 Jakarta** untuk milestone H8Mart, karena TCO simulasi 12 bulan terendah **pada asumsi 35.000 eksekusi/bulan** dan mendukung stack serta verifikasi praktik yang diwajibkan.

## 2. Perbandingan TCO 12 Bulan (USD)

| Peringkat | Opsi | Biaya langsung | Personil | Operasional | Risiko | TCO 12 bulan |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | Self-Hosted (AWS EC2 Jakarta) | 300 | 720 | 240 | 300 | **1.560** |
| 2 | On-Premise (server H8Mart) | 2.520 | 2.160 | 900 | 500 | **6.080** |
| 3 | n8n Cloud (Enterprise, estimasi lab) | 8.640 | 90 | 0 | 100 | **8.830** |

Selisih termurah vs termahal: **USD 7.270**. Asumsi kurs untuk konversi ke rupiah: USD 1 = **Rp16.500**, selisih Rp119.955.000. Plan Enterprise adalah **perkiraan lab**, bukan harga resmi. Perhitungan belum dikurangi kredit AWS Free Tier karena kredit adalah subsidi arus kas, bukan hilangnya biaya sumber daya.

## 3. Kapan selisih biaya tidak boleh jadi dasar keputusan

| Profil klien | Sektor | Kewajiban lokasi data | Dasar regulasi | Rekomendasi advisor |
| --- | --- | --- | --- | --- |
| PT Amanah Finansial (contoh dari handson) | Jasa keuangan | Perlu kajian kewajiban sektor keuangan | Peraturan OJK yang berlaku harus diperiksa | Jangan putuskan hanya dari harga; pilih arsitektur patuh setelah kajian |
| PT Mitra Dana Sejahtera (contoh) | Jasa keuangan | Perlu kajian kewajiban sektor | Peraturan OJK yang berlaku harus diperiksa | Kedudukan data dan DRC dievaluasi sebelum keputusan |
| Bank Harapan Digital (contoh) | Perbankan | Persyaratan infrastruktur dan izin outsourcing sesuai aturan sektor | Peraturan OJK/perbankan yang berlaku | Legal/compliance memvalidasi opsi cloud dan DRC |
| **H8Mart** | Quick-commerce | Tidak dinyatakan wajib data lokal secara spesifik dalam studi kasus | UU 27/2022 Perlindungan Data Pribadi | AWS Jakarta + kontrol akses, enkripsi, backup, minimisasi PII |
| Klinik Sehat Bersama (contoh) | Kesehatan | Data sensitif, perlu kewajiban sektoral dinilai | UU 27/2022 dan peraturan kesehatan terkait | Kepatuhan & keamanan didahulukan sebelum biaya |

Baris non-H8Mart adalah **contoh penalaran kepatuhan dari materi Day 3**, bukan nasihat hukum atau hasil evaluasi pelanggan nyata.

## 4. Biaya tersembunyi yang tidak muncul di invoice

1. Waktu tim untuk patch, troubleshooting, backup, dan pemulihan container (kategori TCO: **personil**).
2. Biaya kesalahan bisnis ketika sinkron stok berhenti tanpa terdeteksi atau refund salah (kategori TCO: **risiko**).

## 5. Catatan untuk pengambil keputusan (3 sampai 5 kalimat, tanpa istilah teknis)

Untuk volume simulasi 35.000 pekerjaan otomatis per bulan, AWS diperkirakan paling hemat selama setahun. Perusahaan tetap harus menyiapkan tenaga untuk menjaga sistem dan menangani gangguan. Kredit AWS membantu mengurangi pembayaran selama periode tertentu, tetapi tidak menghapus biaya operasional jangka panjang. Informasi pelanggan harus dilindungi dan aturan yang berlaku tetap harus dipenuhi. Jika volume jauh lebih kecil, perbandingan perlu dihitung kembali karena layanan Cloud dapat menjadi lebih murah.
