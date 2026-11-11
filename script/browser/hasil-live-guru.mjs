// Copyright (c) 2026 Vassel Goleyu. All rights reserved.
// Uji hasil live: guru piket menekan Selesai, kartu hasil muncul di dashboard guru mapel tanpa reload.
// Prasyarat: aplikasi berjalan (docker compose up), Node 22+, dan Chrome dengan:
//   chrome --headless=new --remote-debugging-port=9333 about:blank
// Jalankan: node script/browser/hasil-live-guru.mjs   (BASE_URL bawaan http://localhost:3100)
import { writeFileSync } from "node:fs";
const B = process.env.BASE_URL || "http://localhost:3100";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
class Http {
  constructor() { this.cookies = {}; }
  jar() { return Object.entries(this.cookies).map(([k, v]) => `${k}=${v}`).join("; "); }
  store(res) { for (const c of res.headers.getSetCookie()) { const [kv] = c.split(";"); const i = kv.indexOf("="); this.cookies[kv.slice(0, i)] = kv.slice(i + 1); } }
  async req(path, opts = {}) { const res = await fetch(B + path, { redirect: "manual", ...opts, headers: { Cookie: this.jar(), ...(opts.headers || {}) } }); this.store(res); return res; }
  async html(path) { return (await this.req(path)).text(); }
  async login(email) {
    const page = await this.html("/session/new");
    const token = page.match(/name="csrf-token" content="([^"]+)"/)[1];
    const res = await this.req("/session", { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: new URLSearchParams({ authenticity_token: token, email_address: email, password: "siaga2026" }) });
    if (res.status !== 302) throw new Error("login gagal");
  }
  async send(method, path, params, csrf) {
    return this.req(path, { method, headers: { "Content-Type": "application/x-www-form-urlencoded", "X-CSRF-Token": csrf, Accept: "text/vnd.turbo-stream.html, text/html" }, body: new URLSearchParams(params) });
  }
}
const targets = await (await fetch("http://localhost:9333/json")).json();
const cdp = new WebSocket(targets.find((t) => t.type === "page").webSocketDebuggerUrl);
await new Promise((r) => (cdp.onopen = r));
let id = 0; const pending = new Map();
cdp.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } };
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); cdp.send(JSON.stringify({ id: i, method, params })); });
const evalJs = async (e) => (await send("Runtime.evaluate", { expression: e, returnByValue: true })).result.result.value;
const shot = async (file) => writeFileSync(file, Buffer.from((await send("Page.captureScreenshot", { format: "png" })).result.data, "base64"));

const sari = new Http(); await sari.login("sari@siaga.test");
await send("Network.enable"); await send("Page.enable");
await send("Network.setCookie", { name: "session_id", value: sari.cookies.session_id, url: B, httpOnly: true });
await send("Emulation.setDeviceMetricsOverride", { width: 1280, height: 900, deviceScaleFactor: 1, mobile: false });
await send("Page.navigate", { url: B + "/kits" });
for (let i = 0; i < 60 && !(await evalJs("!!document.querySelector('turbo-cable-stream-source[connected]')")); i++) await sleep(100);
await evalJs("window.__tanpa_reload = 'ada'");
const stat = () => evalJs("[...document.querySelectorAll('#teacher-live .stat')].map(s => s.textContent.replace(/\\s+/g,' ').trim()).join(' | ')");
const results = () => evalJs("document.querySelectorAll('#teacher-live .result-card').length");
console.log(`[Chrome Sari] /kits terbuka, Cable terhubung. Hasil: ${await results()} | ${await stat()}`);
await shot("/tmp/teacher_before.png");

const wakur = new Http(); await wakur.login("ratna@siaga.test");
const today = new Date().toLocaleDateString("sv-SE", { timeZone: "Asia/Jakarta" });
const form = await wakur.html("/curriculum/absences/new");
const csrfW = form.match(/name="csrf-token" content="([^"]+)"/)[1];
const teacherId = form.match(/<option value="(\d+)">Sari Wulandari/)[1];
await wakur.send("POST", "/curriculum/absences", { teacher_id: teacherId, date: today, reason: "sakit", note: "" }, csrfW);
await sleep(700);
console.log(`[wakur] aktivasi dikirim. Chrome Sari kini: ${await stat()}  (kit jadi "Sedang dipakai" langsung)`);

const rina = new Http(); await rina.login("rina@siaga.test");
const duty = await rina.html("/duty");
const open = [...duty.matchAll(/<article class="ticket duty-card([^"]*)" id="activation_(\d+)"/g)].filter((m) => !m[1].includes("duty-card--done")).map((m) => `/duty/activations/${m[2]}`);
const actPath = open[0];
console.log(`[piket Rina] kartu terbuka: ${open.length}, memilih ${actPath}`);
const show = await rina.html(actPath);
const csrfP = show.match(/name="csrf-token" content="([^"]+)"/)[1];
const att = [...show.matchAll(/action="(\/duty\/activations\/\d+\/attendance_records\/\d+)"/g)].map((m) => m[1]);
const sub = [...show.matchAll(/action="(\/duty\/activations\/\d+\/submissions\/\d+)"/g)].map((m) => m[1]);
console.log(`[piket Rina] membuka ${actPath}: ${att.length} baris kehadiran, ${sub.length} baris pengumpulan`);
if (att[1]) await rina.send("PATCH", att[1], { "attendance_record[status]": "tidak_hadir" }, csrfP);
const scores = [88, 92, 75, 81, 69];
for (const [i, p] of sub.entries()) if (i !== 1) await rina.send("PATCH", p, { "submission[submitted]": "1", "submission[score]": String(scores[i % 5]), "submission[note]": "" }, csrfP);
const t0 = Date.now();
const done = await rina.send("PATCH", actPath + "/complete", {}, csrfP);
console.log(`[piket Rina] tekan Selesai -> HTTP ${done.status}`);

let appeared = null;
const newest = () => evalJs("(document.querySelector('#teacher-live .result-card .muted')||{}).textContent || ''");
for (let i = 0; i < 200; i++) { if ((await newest()).includes("11 Nov 2026")) { appeared = Date.now() - t0; break; } await sleep(25); }
if (appeared === null) { console.log("[Chrome Sari] hasil TIDAK muncul"); process.exit(2); }
console.log(`[Chrome Sari] hasil muncul ${appeared} ms setelah Selesai; tanpa reload: '${await evalJs("window.__tanpa_reload")}'`);
console.log(`[Chrome Sari] ${await stat()}`);
console.log("[Chrome Sari] kartu hasil:", await evalJs("document.querySelector('#teacher-live .result-card').textContent.replace(/\\s+/g,' ').trim()"));
await sleep(500); await shot("/tmp/teacher_after.png");
process.exit(0);
