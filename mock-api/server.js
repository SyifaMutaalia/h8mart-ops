// Mock API H8Mart: Merchant Stock API, Payment API (refund + voucher, Idempotency-Key), Notification API.
// Hanya modul bawaan Node, tanpa dependency. Semua state di memori: restart container = reset.
// Header wajib (kecuali /health): X-Api-Key. Kontrak lengkap: ../data-contract.md
const http = require('http');
const KEY = process.env.MOCK_API_KEY || 'h8mart-mock-key';
const PORT = process.env.PORT || 8080;

// ---------------------------------------------------------------- Merchant Stock API
// Merchant m membawa produk p bila (p*5 + m*3) % 7 < 4 (sama dengan seed/02-seed-data.sql). qty = (p*13 + m*29) % 40 + 5.
const override = new Map([['3:7', 0], ['8:12', 0]]);   // override stok per merchant:produk (juga diubah lewat /admin/stock)
const carries = (m, p) => (p * 5 + m * 3) % 7 < 4;
const qtyOf = (m, p) => (override.has(m + ':' + p) ? override.get(m + ':' + p) : (p * 13 + m * 29) % 40 + 5);
const calls = new Map();         // merchant -> jumlah request stok
let outage = false;              // /admin/stock-outage?on=1: semua merchant menjawab 200 dengan daftar kosong (kegagalan diam-diam)
let slowMs = 2500;               // M007 selalu lambat (default 2,5 detik)

// ---------------------------------------------------------------- Payment + Notification
const refunds = new Map();       // idempotency key -> hasil
const vouchers = new Map();
const messages = [];
let failNext = 0;                // /admin/fail-next?n=2: n request payment berikutnya dijawab 503
let paymentCalls = 0;
let delayNotifyMs = 0;           // /admin/delay-notify?ms=N: tunda jawaban /notify
const send = (res, code, obj) => { res.writeHead(code, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(obj)); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function pay(store, prefix, idem, j, res) {
  paymentCalls++;
  if (!idem) return send(res, 400, { error: 'idempotency_key_required', hint: 'kirim header Idempotency-Key' });
  if (!j.order_id || !(Number(j.amount) > 0)) return send(res, 422, { error: 'invalid_request', hint: 'order_id dan amount (>0) wajib' });
  if (store.has(idem)) return send(res, 200, { ...store.get(idem), replayed: true });
  if (failNext > 0) { failNext--; return send(res, 503, { error: 'payment_gateway_unavailable' }); }
  if (String(j.order_id).endsWith('-099')) return send(res, 503, { error: 'payment_gateway_unavailable', hint: 'order ini selalu gagal (kasus uji dead-letter)' });
  const r = { [prefix + '_id']: (prefix === 'refund' ? 'RF-' : 'VC-') + String(store.size + 1).padStart(5, '0'), order_id: j.order_id, amount: Number(j.amount), status: 'succeeded', replayed: false };
  store.set(idem, r);
  return send(res, 201, r);
}

http.createServer((req, res) => {
  let body = '';
  req.on('data', (c) => (body += c));
  req.on('end', async () => {
    const url = new URL(req.url, 'http://x');
    const path = url.pathname;
    if (path === '/health') return send(res, 200, { status: 'ok' });
    if (req.headers['x-api-key'] !== KEY) return send(res, 401, { error: 'unauthorized', hint: 'header X-Api-Key salah/kosong' });
    let j = {};
    try { j = body ? JSON.parse(body) : {}; } catch (e) { return send(res, 400, { error: 'invalid_json' }); }

    let m;
    if (req.method === 'GET' && (m = path.match(/^\/merchants\/M(\d{3})\/stock$/))) {
      const mi = Number(m[1]);
      if (mi < 1 || mi > 12) return send(res, 404, { error: 'merchant_not_found' });
      const id = 'M' + m[1];
      const n = (calls.get(id) || 0) + 1;
      calls.set(id, n);
      if (mi === 7) await sleep(slowMs);                                   // lambat
      if (mi === 9) return send(res, 500, { error: 'internal_error', hint: 'merchant M009 selalu gagal' });   // gagal permanen
      if (mi === 4 && n % 2 === 1) return send(res, 500, { error: 'internal_error', hint: 'M004 gagal pada panggilan ganjil' });   // gagal sementara
      const items = [];
      if (!outage) for (let p = 1; p <= 30; p++) if (carries(mi, p)) items.push({ sku: 'sku-' + String(p).padStart(3, '0'), qty: String(qtyOf(mi, p)) });
      return send(res, 200, { merchant_id: id, as_of: new Date().toISOString(), items });
    }
    if (req.method === 'POST' && path === '/payments/refunds') return pay(refunds, 'refund', req.headers['idempotency-key'], j, res);
    if (req.method === 'POST' && path === '/payments/vouchers') return pay(vouchers, 'voucher', req.headers['idempotency-key'], j, res);
    if (req.method === 'GET' && path === '/payments/refunds') {
      return send(res, 200, { count: refunds.size, calls: paymentCalls, refunds: [...refunds.entries()].map(([k, v]) => ({ idempotency_key: k, ...v })) });
    }
    if (req.method === 'GET' && path === '/payments/vouchers') {
      return send(res, 200, { count: vouchers.size, calls: paymentCalls, vouchers: [...vouchers.entries()].map(([k, v]) => ({ idempotency_key: k, ...v })) });
    }
    if (req.method === 'POST' && path === '/notify') {
      const msg = { id: messages.length + 1, channel: j.channel || 'ops-alerts', title: j.title || '', text: j.text || '', received_at: new Date().toISOString() };
      messages.push(msg);
      return setTimeout(() => send(res, 201, msg), delayNotifyMs);
    }
    if (req.method === 'GET' && path === '/notify/messages') {
      const ch = url.searchParams.get('channel');
      const list = ch ? messages.filter((x) => x.channel === ch) : messages;
      return send(res, 200, { count: list.length, messages: list });
    }
    // ---- admin (untuk uji kegagalan; bukan bagian kontrak produksi)
    if (req.method === 'POST' && path === '/admin/fail-next') { failNext = Number(url.searchParams.get('n') || 1); return send(res, 200, { fail_next: failNext }); }
    if (req.method === 'POST' && path === '/admin/delay-notify') { delayNotifyMs = Number(url.searchParams.get('ms') || 0); return send(res, 200, { delay_notify_ms: delayNotifyMs }); }
    if (req.method === 'POST' && path === '/admin/stock-outage') { outage = url.searchParams.get('on') === '1'; return send(res, 200, { stock_outage: outage }); }
    if (req.method === 'POST' && path === '/admin/slow-ms') { slowMs = Number(url.searchParams.get('ms') || 2500); return send(res, 200, { m007_delay_ms: slowMs }); }
    if (req.method === 'POST' && (m = path.match(/^\/admin\/stock\/M(\d{3})\/SKU-(\d{3})$/))) {
      override.set(Number(m[1]) + ':' + Number(m[2]), Number(url.searchParams.get('qty') || 0));
      return send(res, 200, { merchant: 'M' + m[1], sku: 'SKU-' + m[2], qty: Number(url.searchParams.get('qty') || 0) });
    }
    if (req.method === 'GET' && path === '/admin/stock-calls') return send(res, 200, Object.fromEntries(calls));
    if (req.method === 'POST' && path === '/admin/reset') {
      refunds.clear(); vouchers.clear(); messages.length = 0; failNext = 0; paymentCalls = 0; delayNotifyMs = 0; outage = false; slowMs = 2500; calls.clear();
      override.clear(); override.set('3:7', 0); override.set('8:12', 0);
      return send(res, 200, { reset: true });
    }
    return send(res, 404, { error: 'not_found' });
  });
}).listen(PORT, () => console.log('mock-api listening on ' + PORT));
