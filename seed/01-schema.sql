-- H8Mart Quick-Commerce Ops: skema core.* (data operasional H8Mart) dan ops.* (tabel kerja otomasi Phase 3).
-- Dijalankan otomatis oleh image postgres saat volume pertama dibuat (urut nama file).
-- Aman dijalankan ulang: schema dihapus dan dibuat lagi, jadi data dan ops.* kembali ke keadaan awal.
DROP SCHEMA IF EXISTS core CASCADE;
DROP SCHEMA IF EXISTS ops CASCADE;
CREATE SCHEMA core;
CREATE SCHEMA ops;

-- ---------------------------------------------------------------- core.* (data H8Mart, hanya dibaca otomasi kecuali dinyatakan lain)
CREATE TABLE core.merchants (
    merchant_id   TEXT PRIMARY KEY,
    name          TEXT NOT NULL,
    zone          TEXT NOT NULL,
    merchant_type TEXT NOT NULL,
    active        BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE core.products (
    product_id TEXT PRIMARY KEY,
    sku        TEXT NOT NULL UNIQUE,
    name       TEXT NOT NULL,
    category   TEXT NOT NULL,
    price      NUMERIC(12, 0) NOT NULL
);

-- Stok per merchant per produk. Diisi dari Merchant Stock API (sinkronisasi berkala), bukan dari order.
CREATE TABLE core.merchant_stock (
    merchant_id TEXT NOT NULL REFERENCES core.merchants,
    product_id  TEXT NOT NULL REFERENCES core.products,
    qty         INTEGER NOT NULL CHECK (qty >= 0),
    synced_at   TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (merchant_id, product_id)
);

CREATE TABLE core.customers (
    customer_id TEXT PRIMARY KEY,
    zone        TEXT NOT NULL
);

CREATE TABLE core.orders (
    order_id       TEXT PRIMARY KEY,
    customer_id    TEXT NOT NULL,
    merchant_id    TEXT NOT NULL REFERENCES core.merchants,
    zone           TEXT NOT NULL,
    order_date     DATE NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL,
    status         TEXT NOT NULL CHECK (status IN ('active', 'delivered', 'cancelled', 'failed')),
    cancel_reason  TEXT,
    total_amount   NUMERIC(12, 0) NOT NULL,
    payment_status TEXT NOT NULL CHECK (payment_status IN ('captured', 'unpaid', 'refunded')),
    customer_note  TEXT
);
CREATE INDEX ON core.orders (order_date, merchant_id);

-- Hari data terakhir: data sintetis berakhir di tanggal ini (tanggal seed dijalankan dikurangi 1 hari). Semua "kemarin"/"hari ini"
-- dalam soal, digest, tool, dan asisten AI merujuk ke tanggal ini, bukan ke jam sistem, supaya angkanya sama kapan pun dikerjakan.
CREATE TABLE core.data_info (
    hari_data_terakhir DATE NOT NULL
);

CREATE TABLE core.order_items (
    order_id   TEXT NOT NULL REFERENCES core.orders,
    product_id TEXT NOT NULL REFERENCES core.products,
    qty        INTEGER NOT NULL,
    unit_price NUMERIC(12, 0) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE core.couriers (
    courier_id TEXT PRIMARY KEY,
    zone       TEXT NOT NULL
);

CREATE TABLE core.deliveries (
    order_id         TEXT PRIMARY KEY REFERENCES core.orders,
    courier_id       TEXT NOT NULL REFERENCES core.couriers,
    promised_minutes INTEGER NOT NULL,
    actual_minutes   INTEGER,
    delivered_at     TIMESTAMPTZ
);

-- ---------------------------------------------------------------- ops.* (ditulis oleh workflow peserta)
CREATE TABLE ops.sync_runs (
    run_id            BIGSERIAL PRIMARY KEY,
    run_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    merchants_total   INTEGER NOT NULL,
    merchants_ok      INTEGER NOT NULL,
    rows_synced       INTEGER NOT NULL,
    new_stockouts     INTEGER NOT NULL DEFAULT 0,
    duration_ms       INTEGER
);

CREATE TABLE ops.tickets (
    ticket_id   BIGSERIAL PRIMARY KEY,
    merchant_id TEXT,
    channel     TEXT NOT NULL DEFAULT 'asisten_ai',
    question    TEXT NOT NULL,
    ai_answer   TEXT,
    reason      TEXT,
    status      TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ops.compensations (
    comp_id         BIGSERIAL PRIMARY KEY,
    order_id        TEXT NOT NULL,
    kind            TEXT NOT NULL DEFAULT 'voucher',
    amount          NUMERIC(12, 0) NOT NULL,
    idempotency_key TEXT NOT NULL UNIQUE,
    status          TEXT NOT NULL CHECK (status IN ('pending', 'issued', 'failed')),
    payment_ref     TEXT,
    note            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ops.refund_actions (
    action_id       BIGSERIAL PRIMARY KEY,
    order_id        TEXT NOT NULL,
    idempotency_key TEXT NOT NULL UNIQUE,
    amount          NUMERIC(12, 0) NOT NULL,
    status          TEXT NOT NULL CHECK (status IN ('pending_approval', 'approved', 'refunded', 'rejected', 'failed')),
    approved_by     TEXT,
    payment_ref     TEXT,
    note            TEXT,
    requested_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ops.dead_letter (
    id            BIGSERIAL PRIMARY KEY,
    workflow      TEXT NOT NULL,
    node          TEXT,
    execution_id  TEXT,
    business_key  TEXT,
    error_message TEXT,
    payload       JSONB,
    attempts      INTEGER NOT NULL DEFAULT 1,
    status        TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'replayed', 'discarded')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Allowlist chat Telegram -> merchant (diisi peserta; sengaja kosong). Dipakai WF3 via Telegram.
CREATE TABLE ops.telegram_merchants (
    chat_id     BIGINT PRIMARY KEY,
    merchant_id TEXT NOT NULL REFERENCES core.merchants (merchant_id),
    label       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
