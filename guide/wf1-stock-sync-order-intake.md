# WF1 · Stock Sync, Order Intake dan Digest Ops

[Guide](README.md) · [Tugas](tasks.md) · cara membaca diagram: [Guide](README.md#cara-membaca-diagram)

WF1 punya **tiga jalur** dengan trigger sendiri-sendiri.

## Syarat

### Minimum (Meet Expectations)

**Jalur A · Sinkron stok**

- **Schedule Trigger tiap 15 menit**.
- Ambil stok tiap merchant dari Merchant Stock API dengan **Retry On Fail**: merchant yang gagal permanen masuk dead-letter, merchant lain tetap diproses.
- Normalisasi (format SKU dan jumlah berbeda dari tabel kita).
- **Merge** dengan katalog produk.
- **Upsert idempotent** ke `core.merchant_stock` (dua kali jalan tidak membuat duplikat).

**Jalur B · Order masuk**

- **Webhook** `order.created` dengan **Header Auth**: cek stok.
- **If/Switch** memutuskan diterima atau ditolak karena stok habis, lalu Respond to Webhook.

**Jalur C · Digest Ops 07.00 WIB**

- Jumlah order, cancel rate, dan SLA 30 menit untuk hari data terakhir, dikirim ke **Telegram** (Send Message, format rapi).
- Salinan ke Notification API boleh sebagai jejak.

### Nilai penuh

- **Jalur A:** deteksi produk yang **baru** menjadi 0 dan laporkan ke tim.
- **Jalur B:** cabang ketiga (diterima dengan peringatan stok tipis); event yang dikirim dua kali tidak membuat order ganda.
- **Jalur C:** alasan batal teratas lewat **MCP Client** ([WF2](wf2-merchant-data-tools.md)); angka digest sama dengan SQL independen atas `core.orders`.

Node pantau di jalur A dan C (`Catat Sync Run`, `Terlalu Lambat?`, `Heartbeat Uptime Kuma`, `Gagal: Sinkron 0 Baris`, `Gagal: Digest Kosong`) adalah bagian pemantauan; rinciannya di [WF5](wf5-reliability-monitoring.md). Minimum cukup **satu** deteksi diam-diam: diagram memakai sinkron 0 baris (jalur A) sebagai contoh, jadi `Digest Kosong?` dan `Gagal: Digest Kosong` di jalur C bergaris putus.

## Diagram

**Jalur A · Sinkron stok tiap 15 menit**

```mermaid
---
config:
  look: classic
  flowchart:
    subGraphTitleMargin:
      top: 12
      bottom: 12
---
flowchart TB
  subgraph AMBIL["Ambil stok tiap merchant"]
    direction LR
    A1(["Jadwal Sinkron 15 Menit"]) --> A2["Ambil Daftar Merchant"]
    A2 --> A3["Loop Per Merchant"]
    A3 -->|loop| A4["Ambil Stok Merchant API<br/>Retry On Fail"]
    A4 -->|sukses| A3
    A4 -. error .-> A5["Catat Dead-Letter"]
    A5 -.-> A6["Alert Merchant Gagal"]
    A6 -.-> A3
  end
  subgraph OLAH["Olah dan simpan"]
    direction LR
    A7["Normalisasi Stok"] --> A8{"Ada Baris Stok?"}
    A8 -->|ya| A9["Ambil Katalog Produk"]
    A8 -->|ya| A10["Gabungkan Katalog<br/>Merge"]
    A9 --> A10
    A10 --> A11["Upsert Stok"]
    A8 -. tidak .-> A12["Gagal: Sinkron 0 Baris"]
  end
  subgraph PANTAU["Catat dan pantau"]
    direction LR
    A13["Catat Sync Run"] --> A14{"Terlalu Lambat?"}
    A14 -->|ya| A15["Alert Perlambatan"]
    A14 -->|tidak| A16["Heartbeat Uptime Kuma"]
    A15 --> A16
    A16 -.-> A17{"Ada Produk<br/>Habis Baru?"}
    A17 -.->|ya| A18["Laporkan Produk Habis"]
  end
  AMBIL -->|done| OLAH
  OLAH --> PANTAU
  linkStyle default stroke-width:3px
  classDef navy fill:#1C4587,stroke:#1C4587,color:#FFFFFF
  classDef orange fill:#F06634,stroke:#F06634,color:#FFFFFF
  classDef opt fill:none,stroke:#F06634,stroke-width:3px,stroke-dasharray:6 4
  class A1,A2,A3,A4,A5,A6,A13,A14,A15,A16 navy
  class A7,A8,A9,A10,A11,A12 orange
  class A17,A18 opt
  style AMBIL fill:none,stroke:#1C4587,stroke-width:3px
  style OLAH fill:none,stroke:#F06634,stroke-width:3px
  style PANTAU fill:none,stroke:#1C4587,stroke-width:3px
```

![Contoh canvas WF1 jalur A](../assets/wf1-a-sinkron.png)


**Jalur B · Order masuk**

```mermaid
---
config:
  look: classic
  flowchart:
    subGraphTitleMargin:
      top: 12
      bottom: 12
---
flowchart LR
  subgraph TERIMA["Terima dan cek"]
    B1(["Webhook order.created<br/>Header Auth"]) --> B2{"Event Valid?"}
    B2 -->|ya| B3["Cek Stok Order"]
    B3 --> B4{"Routing Stok<br/>Switch"}
  end
  subgraph JAWAB["Catat dan jawab"]
    B5["Catat Order"] --> B6["Respon 200 Diterima"]
    B7["Respon 409 Stok Habis"]
    B8["Respon 422 Tidak Valid"]
  end
  B4 -->|cukup| B5
  B4 -.->|tipis| B5
  B4 -->|habis| B7
  B2 -->|tidak| B8
  linkStyle default stroke-width:3px
  classDef navy fill:#1C4587,stroke:#1C4587,color:#FFFFFF
  classDef orange fill:#F06634,stroke:#F06634,color:#FFFFFF
  class B1,B2,B3,B4 navy
  class B5,B6,B7,B8 orange
  style TERIMA fill:none,stroke:#1C4587,stroke-width:3px
  style JAWAB fill:none,stroke:#F06634,stroke-width:3px
```

![Contoh canvas WF1 jalur B](../assets/wf1-b-order.png)


**Jalur C · Digest Ops 07.00 WIB**

```mermaid
---
config:
  look: classic
  flowchart:
    subGraphTitleMargin:
      top: 12
      bottom: 12
---
flowchart LR
  subgraph HITUNG["Hitung dan periksa"]
    C1(["Jadwal Digest 07.00 WIB<br/>Asia/Jakarta"]) --> C2["Hitung KPI Harian"]
    C2 --> C3{"Digest Kosong?"}
    C3 -. ya .-> C4["Gagal: Digest Kosong"]
  end
  subgraph KIRIM["Susun dan kirim"]
    C7["Kirim Digest Telegram"] -.-> C8["Kirim Digest Notification<br/>jejak, opsional"]
    C5["Alasan Batal Teratas<br/>MCP Client"] -.-> C6["Tambah Alasan<br/>ke Digest"]
  end
  C3 -.->|tidak| C5
  C6 -.-> C7
  C3 -->|tidak| C7
  linkStyle default stroke-width:3px
  classDef navy fill:#1C4587,stroke:#1C4587,color:#FFFFFF
  classDef orange fill:#F06634,stroke:#F06634,color:#FFFFFF
  classDef opt fill:none,stroke:#F06634,stroke-width:3px,stroke-dasharray:6 4
  class C1,C2 navy
  class C7 orange
  class C3,C4,C5,C6,C8 opt
  style HITUNG fill:none,stroke:#1C4587,stroke-width:3px
  style KIRIM fill:none,stroke:#F06634,stroke-width:3px
```

![Contoh canvas WF1 jalur C](../assets/wf1-c-digest.png)

