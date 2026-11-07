# WF3 · Asisten AI Merchant

[Guide](README.md) · [Tugas](tasks.md) · cara membaca diagram: [Guide](README.md#cara-membaca-diagram)

## Syarat

### Minimum (Meet Expectations)

- **AI Agent** dengan **OpenAI Chat Model `gpt-6-luna`** menjawab pertanyaan merchant dari tool [WF2](wf2-merchant-data-tools.md) (MCP Client Tool). API key OpenAI dibagikan instruktur, dipakai lewat credential n8n (bukan di workflow); Anthropic Claude opsional bila punya key sendiri.
- Output **terstruktur** (Structured Output Parser): `jawaban`, `data_dipakai`, `confidence`, `perlu_eskalasi`.
- **Guardrail:** confidence rendah, data tidak cukup, atau `perlu_eskalasi` berarti pertanyaan diteruskan ke CS (baris di `ops.tickets`), bukan dijawab AI. Agent **tidak menjanjikan kompensasi atau memutuskan refund**; pertanyaan kompensasi dieskalasi ke CS.
- **Fallback:** agent gagal atau output tidak valid tidak menjatuhkan workflow (On Error: `Continue (using error output)`), hasilnya eskalasi ke CS.
- **Webhook production Published dengan Respond to Webhook** (kontrak: [data-contract.md](../data-contract.md) bagian 5).

### Nilai penuh

- Catatan pelanggan dan pertanyaan diperlakukan sebagai **data tidak tepercaya**: agent tidak menjalankan instruksi di dalamnya dan tidak mengambil data merchant lain.
- **Dev set `fixtures/dev-set-asisten.json` dijalankan dan hasilnya dilaporkan** (tabel aktual vs label).
- **Chat asisten lewat Telegram:** Telegram Trigger di instance HTTPS memakai logika yang sama dengan **allowlist `chat_id`** ke `merchant_id` (chat asing ditolak sopan). Boleh workflow terpisah (`wf3b-<nama>.json`). Aturan Telegram: [telegram-bot.md](telegram-bot.md).

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
flowchart LR
  subgraph MASUK["Pertanyaan dan agent"]
    Q(["Terima Pertanyaan<br/>Webhook"]) --> D["Ambil Hari Data Terakhir"]
    D --> AG["Asisten Merchant<br/>AI Agent"]
  end
  subgraph JAWAB["Guardrail dan balasan"]
    G{"Lolos Guardrail?"}
    J["Balas Dijawab<br/>Respond to Webhook"]
    FB["Fallback: AI Gagal"]
    E["Buat Tiket CS"]
    RE["Balas Eskalasi<br/>Respond to Webhook"]
  end
  AG -->|sukses| G
  AG -. error .-> FB
  G -->|ya| J
  G -->|tidak| E
  FB --> E
  E --> RE
  linkStyle default stroke-width:3px
  classDef navy fill:#1C4587,stroke:#1C4587,color:#FFFFFF
  classDef orange fill:#F06634,stroke:#F06634,color:#FFFFFF
  class Q,D,AG navy
  class G,J,FB,E,RE orange
  style MASUK fill:none,stroke:#1C4587,stroke-width:3px
  style JAWAB fill:none,stroke:#F06634,stroke-width:3px
```

![Contoh canvas WF3](../assets/wf3-asisten.png)


Chat asisten lewat Telegram (nilai penuh) boleh dibuat sebagai workflow terpisah yang meneruskan pertanyaan ke Webhook WF3, sehingga logika agent tetap satu:

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
  subgraph TELE["Chat Telegram: workflow terpisah, nilai penuh"]
    direction LR
    TT(["Telegram Trigger"]) --> TC["Cek Allowlist<br/>ops.telegram_merchants"]
    TC --> TA{"Chat Terdaftar?"}
    TA -->|ya| TQ["Tanya Asisten WF3<br/>HTTP Request"]
    TQ --> TB["Kirim Jawaban ke Chat"]
    TA -->|tidak| TX["Balas Chat Asing"]
  end
  linkStyle default stroke-width:3px
  classDef navy fill:#1C4587,stroke:#1C4587,color:#FFFFFF
  classDef orange fill:#F06634,stroke:#F06634,color:#FFFFFF
  classDef opt fill:none,stroke:#F06634,stroke-width:3px,stroke-dasharray:6 4
  class TT,TC,TA,TQ,TB,TX opt
  style TELE fill:none,stroke:#F06634,stroke-width:3px,stroke-dasharray:6 4
```

<img src="../assets/wf3-telegram.png" alt="Contoh canvas chat Telegram" width="700">

