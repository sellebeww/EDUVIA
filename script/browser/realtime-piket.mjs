// Copyright (c) 2026 Vassel Goleyu. All rights reserved.
// Uji realtime dua browser: wakil kurikulum menekan Aktifkan, kartu muncul di Chrome guru piket tanpa reload.
// Prasyarat: aplikasi berjalan (docker compose up), Node 22+, dan Chrome dengan:
//   chrome --headless=new --remote-debugging-port=9333 about:blank
// Jalankan: node script/browser/realtime-piket.mjs   (BASE_URL bawaan http://localhost:3100)
// Dua browser: Chrome asli (guru piket) membuka /duty; wakil kurikulum menekan "Aktifkan" lewat HTTP.
// Kartu harus muncul di Chrome tanpa reload.
import { writeFileSync } from "node:fs";
const B = process.env.BASE_URL || "http://localhost:3100";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

class Http {
  constructor() { this.cookies = {}; }
  jar() { return Object.entries(this.cookies).map(([k, v]) => `${k}=${v}`).join("; "); }
  store(res) { for (const c of res.headers.getSetCookie()) { const [kv] = c.split(";"); const i = kv.indexOf("="); this.cookies[kv.slice(0, i)] = kv.slice(i + 1); } }
  async req(path, opts = {}) { const res = await fetch(B + path, { redirect: "manual", ...opts, headers: { Cookie: this.jar(), ...(opts.headers || {}) } }); this.store(res); return res; }
  async login(email) {
    const page = await (await this.req("/session/new")).text();
    const token = page.match(/name="csrf-token" content="([^"]+)"/)[1];
    const res = await this.req("/session", { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ authenticity_token: token, email_address: email, password: "siaga2026" }) });
    if (res.status !== 302) throw new Error("login gagal " + res.status);
  }
}

const targets = await (await fetch("http://localhost:9333/json")).json();
const page = targets.find((t) => t.type === "page");
const cdp = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((r) => (cdp.onopen = r));
let id = 0; const pending = new Map();
cdp.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } };
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); cdp.send(JSON.stringify({ id: i, method, params })); });
const evalJs = async (expression) => (await send("Runtime.evaluate", { expression, returnByValue: true })).result.result.value;

const piket = new Http(); await piket.login("rina@siaga.test");
await send("Network.enable");
await send("Network.setCookie", { name: "session_id", value: piket.cookies.session_id, url: B, httpOnly: true });
await send("Page.enable"); await send("Emulation.setDeviceMetricsOverride", { width: 1280, height: 760, deviceScaleFactor: 1, mobile: false });
await send("Page.navigate", { url: B + "/duty" });
for (let i = 0; i < 60 && !(await evalJs("document.readyState === 'complete'")); i++) await sleep(100);
for (let i = 0; i < 60 && !(await evalJs("!!document.querySelector('turbo-cable-stream-source[connected]')")); i++) await sleep(100);
await evalJs("window.__tanpa_reload = 'ada'");
const before = await evalJs("document.querySelectorAll('.duty-card').length");
console.log(`[Chrome piket] /duty terbuka. Kartu: ${before}. Cable terhubung: ${await evalJs("!!document.querySelector('turbo-cable-stream-source[connected]')")}`);
writeFileSync("/tmp/duty_before.png", Buffer.from((await send("Page.captureScreenshot", { format: "png" })).result.data, "base64"));

const wakur = new Http(); await wakur.login("ratna@siaga.test");
const today = new Date().toLocaleDateString("sv-SE", { timeZone: "Asia/Jakarta" });
const form = await (await wakur.req("/curriculum/absences/new")).text();
const token = form.match(/name="csrf-token" content="([^"]+)"/)[1];
const teacherId = form.match(/<option value="(\d+)">Sari Wulandari/)[1];
const t0 = Date.now();
const res = await wakur.req("/curriculum/absences", { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" },
  body: new URLSearchParams({ authenticity_token: token, teacher_id: teacherId, date: today, reason: "sakit", note: "" }) });
console.log(`[wakur] POST /curriculum/absences (${today}) -> HTTP ${res.status}, selesai ${Date.now() - t0} ms`);

let appeared = null;
for (let i = 0; i < 200; i++) { if ((await evalJs("document.querySelectorAll('.duty-card').length")) > before) { appeared = Date.now() - t0; break; } await sleep(25); }
if (appeared === null) { console.log("[Chrome piket] kartu TIDAK muncul dalam 5 detik"); process.exit(2); }
console.log(`[Chrome piket] kartu muncul ${appeared} ms setelah klik wakur`);
console.log(`[Chrome piket] halaman TIDAK dimuat ulang: penanda window tetap '${await evalJs("window.__tanpa_reload")}'`);
console.log("[Chrome piket] kartu:", JSON.stringify(await evalJs("[...document.querySelectorAll('.duty-card')].map(c => c.querySelector('.duty-card__slot').textContent.trim() + ' | ' + c.querySelector('.duty-card__title').textContent.trim() + ' | ' + c.querySelector('.duty-card__kit').textContent.replace(/\\s+/g,' ').trim())")));
await sleep(900);
writeFileSync("/tmp/duty_after.png", Buffer.from((await send("Page.captureScreenshot", { format: "png" })).result.data, "base64"));
process.exit(0);
