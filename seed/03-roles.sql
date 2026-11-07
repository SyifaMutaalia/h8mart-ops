-- Role terpisah (least privilege). Password dibaca dari environment container postgres (lihat compose.yaml / .env).
--   mcp_reader : hanya SELECT (core.*, ops.*)                          -> credential WF2 (MCP) dan WF3
--   ops_writer : SELECT core.*, tulis core.merchant_stock/orders/order_items + ops.*  -> credential WF1, WF4, WF5
-- Aman dijalankan ulang (role dibuat hanya bila belum ada, izin diberikan ulang).
\set reader_pw `echo "$PG_READER_PASSWORD"`
\set writer_pw `echo "$PG_WRITER_PASSWORD"`
SELECT format('CREATE ROLE mcp_reader LOGIN PASSWORD %L', :'reader_pw') WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mcp_reader') \gexec
SELECT format('CREATE ROLE ops_writer LOGIN PASSWORD %L', :'writer_pw') WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ops_writer') \gexec
GRANT USAGE ON SCHEMA core, ops TO mcp_reader, ops_writer;
GRANT SELECT ON ALL TABLES IN SCHEMA core, ops TO mcp_reader, ops_writer;
GRANT INSERT, UPDATE ON core.merchant_stock TO ops_writer;
GRANT INSERT ON core.orders, core.order_items TO ops_writer;
GRANT INSERT, UPDATE ON ALL TABLES IN SCHEMA ops TO ops_writer;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ops TO ops_writer;
ALTER ROLE mcp_reader SET default_transaction_read_only = on;
