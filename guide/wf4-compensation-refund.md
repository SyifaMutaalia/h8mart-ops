# WF4 · Kompensasi dan Refund

[Guide](README.md) · [Tugas](tasks.md) · cara membaca diagram: [Guide](README.md#cara-membaca-diagram)

## Syarat

### Minimum (Meet Expectations)

- Webhook menerima `delivery.late` dan `order.failed`.
- **Kebijakan rule-based yang kalian tetapkan dan dokumentasikan**, dengan ambang dan nominal ditulis eksplisit:
  - voucher keterlambatan **otomatis** sampai ambang tertentu;
  - refund di atas ambang **butuh approval Ops**.
- **Approval lewat bot Telegram:** node **Send and Wait for Response** (Approval, tombol Approve dan Decline) mengirim pesan ke chat Ops kalian.
  - Tombolnya baru bisa dipakai setelah VPS HTTPS hidup ([telegram-bot.md](telegram-bot.md)).
  - Selama lokal, uji jalur ini dengan **Wait node** (resume URL dibuka di browser laptop). Wait node dengan resume URL atau form tetap boleh sebagai alternatif bila tombol Telegram tidak dipakai.
- Keputusan tercatat di `ops.refund_actions`.
- Panggilan ke **Payment API dengan `Idempotency-Key`**, lalu **Notification API**, lalu catat di `ops.compensations` dan `ops.refund_actions`.
- Kegagalan Payment yang tidak pulih masuk dead-letter.

### Nilai penuh

- Voucher dan refund **hanya sekali** walau event atau approval terkirim dua kali.
- Ops bisa menolak (tercatat, Payment tidak dipanggil).
- Nominal refund = `core.orders.total_amount`.
- Retry Payment terbukti.

## Diagram

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
  subgraph EVENT["Event dan kebijakan"]
    direction LR
    W(["Terima Event"]) --> O["Ambil Order"]
    O --> K["Tentukan Kebijakan"]
    K --> T{"Jenis Event?<br/>Switch"}
  end
  subgraph VOUCHER["delivery.late: voucher otomatis"]
    direction LR
    V1["Catat Voucher"] --> V2["Panggil Payment Voucher"]
    V2 --> V3["Notifikasi Voucher"]
  end
  subgraph REFUND["order.failed: refund"]
    direction LR
    R1["Catat Usulan Refund"] --> R2{"Perlu Approval?"}
    R2 -->|ya| R3["Minta Approval Telegram<br/>Send and Wait"]
    R3 --> R4{"Disetujui?"}
    R2 -->|tidak| R5["Panggil Payment Refund"]
    R4 -->|ya| R5
    R4 -.->|tidak| R6["Tandai Ditolak"]
    R5 --> R7["Catat Refund Selesai"]
    R7 --> R8["Notifikasi Refund"]
    R5 -. error .-> R9["Catat Dead-Letter"]
    R9 -.-> R10["Gagal: Payment"]
  end
  EVENT -->|delivery.late| VOUCHER
  EVENT -->|order.failed| REFUND
  VOUCHER ~~~ REFUND
  linkStyle default stroke-width:3px
  classDef navy fill:#1C4587,stroke:#1C4587,color:#FFFFFF
  classDef orange fill:#F06634,stroke:#F06634,color:#FFFFFF
  classDef opt fill:none,stroke:#F06634,stroke-width:3px,stroke-dasharray:6 4
  class W,O,K,T,R1,R2,R3,R4,R5,R7,R8,R9,R10 navy
  class V1,V2,V3 orange
  class R6 opt
  style EVENT fill:none,stroke:#1C4587,stroke-width:3px
  style VOUCHER fill:none,stroke:#F06634,stroke-width:3px
  style REFUND fill:none,stroke:#1C4587,stroke-width:3px
```

![Contoh canvas WF4](../assets/wf4-kompensasi.png)

