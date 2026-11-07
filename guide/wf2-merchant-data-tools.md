# WF2 · Merchant Data Tools (MCP Server)

[Guide](README.md) · [Tugas](tasks.md) · cara membaca diagram: [Guide](README.md#cara-membaca-diagram)

## Syarat

### Minimum (Meet Expectations)

- **MCP Server Trigger** dengan **tiga tool read-only berparameter** (nama tool bebas):
  - **KPI per merchant** untuk satu tanggal, termasuk **SLA per merchant**.
  - **Alasan batal** per merchant untuk satu tanggal beserta **contoh catatan pelanggan** (teks bebas pelanggan = data tidak tepercaya).
  - **Status stok** per merchant (dan/atau per SKU).
- Credential database memakai role **`mcp_reader`**.
- Tool dipanggil **agent [WF3](wf3-ai-merchant-assistant.md) lewat MCP Client Tool**.

### Nilai penuh

- Tool juga dipakai lewat **MCP Client** (langkah deterministik dengan parameter tetap, mis. di digest [WF1](wf1-stock-sync-order-intake.md)).
- Bukti `INSERT` lewat `mcp_reader` ditolak.

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
  subgraph PAKAI["Pemakai tool"]
    U1["MCP Client Tool<br/>di agent WF3"]
    U2["MCP Client<br/>di digest WF1"]
  end
  subgraph SERVER["WF2 · MCP Server"]
    T(["MCP Server Trigger"])
    K1["Tool KPI Merchant"]
    K2["Tool Alasan Batal"]
    K3["Tool Status Stok"]
  end
  subgraph DATA["Database"]
    R["Credential mcp_reader<br/>read-only"] --> DB[("PostgreSQL h8mart")]
  end
  U1 --> T
  U2 -.-> T
  T --> K1
  T --> K2
  T --> K3
  K1 --> R
  K2 --> R
  K3 --> R
  linkStyle default stroke-width:3px
  classDef navy fill:#1C4587,stroke:#1C4587,color:#FFFFFF
  classDef orange fill:#F06634,stroke:#F06634,color:#FFFFFF
  classDef opt fill:none,stroke:#F06634,stroke-width:3px,stroke-dasharray:6 4
  class U1,R,DB navy
  class T,K1,K2,K3 orange
  class U2 opt
  style PAKAI fill:none,stroke:#1C4587,stroke-width:3px
  style SERVER fill:none,stroke:#F06634,stroke-width:3px
  style DATA fill:none,stroke:#1C4587,stroke-width:3px
```

<img src="../assets/wf2-mcp-tools.png" alt="Contoh canvas WF2" width="380">

