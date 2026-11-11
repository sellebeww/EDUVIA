// Copyright (c) 2026 Vassel Goleyu. All rights reserved.
// Uji simpan otomatis lembar lewat klik sungguhan (Stimulus di bawah CSP), dan cek error JS/CSP.
// Prasyarat: aplikasi berjalan (docker compose up), Node 22+, dan Chrome dengan:
//   chrome --headless=new --remote-debugging-port=9333 about:blank
// Jalankan: node script/browser/simpan-otomatis.mjs   (BASE_URL bawaan http://localhost:3100)
const B = process.env.BASE_URL || "http://localhost:3100";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
class Http {
  constructor() { this.cookies = {}; }
  jar() { return Object.entries(this.cookies).map(([k, v]) => `${k}=${v}`).join("; "); }
  store(res) { for (const c of res.headers.getSetCookie()) { const [kv] = c.split(";"); const i = kv.indexOf("="); this.cookies[kv.slice(0, i)] = kv.slice(i + 1); } }
  async req(path, opts = {}) { const res = await fetch(B + path, { redirect: "manual", ...opts, headers: { Cookie: this.jar(), ...(opts.headers || {}) } }); this.store(res); return res; }
  async login(email) { const page = await (await this.req("/session/new")).text(); const token = page.match(/name="csrf-token" content="([^"]+)"/)[1];
    await this.req("/session", { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: new URLSearchParams({ authenticity_token: token, email_address: email, password: "siaga2026" }) }); }
}
const targets = await (await fetch("http://localhost:9333/json")).json();
const cdp = new WebSocket(targets.find((t) => t.type === "page").webSocketDebuggerUrl);
await new Promise((r) => (cdp.onopen = r));
let id = 0; const pending = new Map(); const problems = [];
cdp.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  if (m.method === "Runtime.exceptionThrown") problems.push("JS " + m.params.exceptionDetails.text);
  if (m.method === "Log.entryAdded" && m.params.entry.level === "error") problems.push("LOG " + m.params.entry.text); };
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); cdp.send(JSON.stringify({ id: i, method, params })); });
const evalJs = async (e) => (await send("Runtime.evaluate", { expression: e, returnByValue: true })).result.result?.value;
await send("Network.enable"); await send("Page.enable"); await send("Runtime.enable"); await send("Log.enable");

const rina = new Http(); await rina.login("rina@siaga.test");
const duty = await (await rina.req("/duty")).text();
const open = [...duty.matchAll(/<article class="ticket duty-card([^"]*)" id="activation_(\d+)"/g)].filter((m) => !m[1].includes("done")).map((m) => m[2]);
await send("Network.setCookie", { name: "session_id", value: rina.cookies.session_id, url: B, httpOnly: true });
await send("Page.navigate", { url: `${B}/duty/activations/${open[0]}` });
for (let i = 0; i < 60 && !(await evalJs("document.readyState === 'complete'")); i++) await sleep(100);
await sleep(600);
console.log("[Chrome] lembar dibuka:", await evalJs("document.querySelector('#sheet-summary').textContent.replace(/\\s+/g,' ').trim()"));
console.log("[Chrome] Stimulus terpasang pada form:", await evalJs("document.querySelectorAll('form[data-controller=autosave]').length"));
// 1) klik 'Tidak hadir' pada siswa pertama -> simpan otomatis
await evalJs("document.querySelector('input[id$=\"_tidak_hadir\"]').click()");
let ok = false, t0 = Date.now();
for (let i = 0; i < 80; i++) { if ((await evalJs("document.querySelector('#sheet-summary').textContent")).match(/Hadir\s+(\d+) dari/)?.[1] && await evalJs("!!document.querySelector('.saved-tick')")) { ok = true; break; } await sleep(50); }
console.log(`[Chrome] klik 'Tidak hadir' -> tersimpan otomatis & centang muncul: ${ok} (${Date.now() - t0} ms). Ringkasan: ${await evalJs("document.querySelector('#sheet-summary').textContent.replace(/\\s+/g,' ').trim()")}`);
// 2) ketik nilai (debounce) tanpa menekan tombol
await evalJs("(() => { const i = document.querySelector('input.sheet-score'); i.focus(); i.value = '88'; i.dispatchEvent(new Event('input', { bubbles: true })); })()");
await sleep(1500);
const show = await (await rina.req(`/duty/activations/${open[0]}`)).text();
console.log("[server] nilai 88 tersimpan di database:", /value="88"/.test(show), "| status tidak_hadir tersimpan:", /id="attendance_record_\d+_tidak_hadir"[^>]*checked/.test(show));
console.log(problems.length ? "MASALAH: " + JSON.stringify(problems) : "[Chrome] tanpa error JS / pelanggaran CSP selama interaksi");
process.exit(0);
