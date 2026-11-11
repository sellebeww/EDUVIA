# Uji perilaku di browser (Chrome DevTools Protocol)

Skrip ini melengkapi tes Minitest dengan pembuktian di **Chrome sungguhan**: realtime lewat WebSocket, simpan otomatis (Stimulus) di bawah Content-Security-Policy, dan tangkapan layar yang sekaligus melaporkan error JavaScript atau pelanggaran CSP.

```bash
docker compose down -v && docker compose up -d     # data seed baru
chrome --headless=new --remote-debugging-port=9333 about:blank &
node script/browser/realtime-piket.mjs             # kartu tiba di guru piket tanpa reload
node script/browser/hasil-live-guru.mjs            # hasil tiba di dashboard guru mapel
node script/browser/simpan-otomatis.mjs            # klik → tersimpan; ketik nilai → tersimpan
```

Skrip mengasumsikan data seed bawaan dan akun demo (`siaga2026`). `BASE_URL` mengubah alamat aplikasi.
Bukan bagian dari `rails test`; ini alat verifikasi manual yang bisa diulang.
