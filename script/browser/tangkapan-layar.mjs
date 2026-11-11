// Copyright (c) 2026 Vassel Goleyu. All rights reserved.
// Tangkapan layar halaman per peran (terang/gelap/ponsel) sekaligus melaporkan error JS, log, dan HTTP >= 400. Env: OUT=folder SHOTS='[{...}]'.
// Prasyarat: aplikasi berjalan (docker compose up), Node 22+, dan Chrome dengan:
//   chrome --headless=new --remote-debugging-port=9333 about:blank
// Jalankan: node script/browser/tangkapan-layar.mjs   (BASE_URL bawaan http://localhost:3100)
import { writeFileSync, mkdirSync } from "node:fs";
const B = process.env.BASE_URL || "http://localhost:3100", OUT = process.env.OUT;
mkdirSync(OUT, { recursive: true });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
class Http {
  constructor() { this.cookies = {}; }
  jar() { return Object.entries(this.cookies).map(([k, v]) => `${k}=${v}`).join("; "); }
  store(res) { for (const c of res.headers.getSetCookie()) { const [kv] = c.split(";"); const i = kv.indexOf("="); this.cookies[kv.slice(0, i)] = kv.slice(i + 1); } }
  async req(path, opts = {}) { const res = await fetch(B + path, { redirect: "manual", ...opts, headers: { Cookie: this.jar(), ...(opts.headers || {}) } }); this.store(res); return res; }
  async login(email) {
    const page = await (await this.req("/session/new")).text();
    const token = page.match(/name="csrf-token" content="([^"]+)"/)[1];
    await this.req("/session", { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: new URLSearchParams({ authenticity_token: token, email_address: email, password: "siaga2026" }) });
  }
}
// siapkan data hari ini: wakur mengaktifkan Sari
const wakur = new Http(); await wakur.login("ratna@siaga.test");
const form = await (await wakur.req("/curriculum/absences/new")).text();
const csrf = form.match(/name="csrf-token" content="([^"]+)"/)[1];
const teacherId = form.match(/<option value="(\d+)">Sari Wulandari/)[1];
const today = new Date().toLocaleDateString("sv-SE", { timeZone: "Asia/Jakarta" });
await wakur.req("/curriculum/absences", { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: new URLSearchParams({ authenticity_token: csrf, teacher_id: teacherId, date: today, reason: "sakit", note: "" }) });

const targets = await (await fetch("http://localhost:9333/json")).json();
const cdp = new WebSocket(targets.find((t) => t.type === "page").webSocketDebuggerUrl);
await new Promise((r) => (cdp.onopen = r));
let id = 0; const pending = new Map();
cdp.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } };
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); cdp.send(JSON.stringify({ id: i, method, params })); });
const evalJs = async (e) => (await send("Runtime.evaluate", { expression: e, returnByValue: true })).result.result?.value;
await send("Network.enable"); await send("Page.enable"); await send("Runtime.enable"); await send("Log.enable");
const problems = [];
cdp.addEventListener("message", (e) => { const m = JSON.parse(e.data); if (m.method === "Runtime.exceptionThrown") problems.push("JS: " + (m.params.exceptionDetails.exception?.description || m.params.exceptionDetails.text).split("\n")[0]); if (m.method === "Log.entryAdded" && ["error"].includes(m.params.entry.level)) problems.push("LOG: " + m.params.entry.text + " " + (m.params.entry.url || "")); if (m.method === "Network.responseReceived" && m.params.response.status >= 400) problems.push("HTTP " + m.params.response.status + " " + m.params.response.url); });

const shots = JSON.parse(process.env.SHOTS);
let current = null, http = null;
for (const s of shots) {
  if (s.login !== current) {
    await send("Network.clearBrowserCookies");
    if (s.login) { http = new Http(); await http.login(s.login + "@siaga.test"); await send("Network.setCookie", { name: "session_id", value: http.cookies.session_id, url: B, httpOnly: true }); }
    current = s.login;
  }
  await send("Emulation.setEmulatedMedia", { features: [{ name: "prefers-color-scheme", value: s.scheme || "light" }, { name: "prefers-reduced-motion", value: s.still ? "reduce" : "no-preference" }] });
  await send("Emulation.setDeviceMetricsOverride", { width: s.w || 1280, height: 800, deviceScaleFactor: s.dpr || 1, mobile: !!s.mobile });
  await send("Page.navigate", { url: B + s.path });
  for (let i = 0; i < 80 && !(await evalJs("document.readyState === 'complete'")); i++) await sleep(100);
  await sleep(s.wait || 1600);
  const h = Math.min(await evalJs("Math.ceil(document.documentElement.scrollHeight)"), s.maxh || 2400);
  await send("Emulation.setDeviceMetricsOverride", { width: s.w || 1280, height: h, deviceScaleFactor: s.dpr || 1, mobile: !!s.mobile });
  await sleep(200);
  writeFileSync(`${OUT}/${s.name}.png`, Buffer.from((await send("Page.captureScreenshot", { format: "png" })).result.data, "base64"));
  console.log("ok", s.name, h, problems.length ? "MASALAH: " + JSON.stringify(problems.splice(0)) : "tanpa error");
}
process.exit(0);
