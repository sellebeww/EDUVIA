<p align="center">
  <img src="logo/png/eduvia-logo-light.png" alt="EDUVIA" width="420">
</p>

# Siaga Kelas

> **Jam kosong bukan lagi jam bebas.**

Siaga Kelas membantu sekolah menangani kelas kosong saat guru mapel berhalangan. Guru menyiapkan **kit siaga** lebih dulu (tugas mandiri 30–40 menit, kunci jawaban, petunjuk untuk pengawas non-ahli). Saat guru berhalangan, wakil kurikulum menekan **satu tombol** dan kit yang sesuai jadwal langsung terkirim ke guru piket, lengkap dengan lembar kehadiran dan pengumpulan. Hasil belajar kembali ke guru pemilik materi.

Pembeda: **kesiapsiagaan, bukan reaksi.** Kit terikat ke jadwal pelajaran dan fase kurikulum.

> Soal kebaruan: belum menemukan alat serupa dalam pencarian terbatas, perlu diverifikasi lebih lanjut.

## Status

MVP sedang dibangun bertahap. Rencana lengkap: [docs/PLAN.md](docs/PLAN.md). Keputusan desain: [docs/DECISIONS.md](docs/DECISIONS.md). Ide lanjutan: [docs/FUTURE.md](docs/FUTURE.md).

| Fase | Isi | Status |
|---|---|---|
| 0 | Perencanaan | selesai |
| 1 | Fondasi: Rails 8, Docker, autentikasi, peran, layout, seed | selesai |
| 2 | Domain inti: model, jadwal, kelas, mapel, piket, transisi status kit | selesai |
| 3 | Bank kit: CRUD, templat, lampiran PDF, filter | selesai |
| 4 | Aktivasi satu tombol + realtime (Turbo Streams, Solid Cable) | selesai |
| 5 | Kehadiran, pengumpulan, hasil, laporan | belum |
| 6 | Poles dan serah terima | belum |

## Stack

Ruby on Rails 8, PostgreSQL, Hotwire (Turbo + Stimulus), HTML5 + CSS3 murni, Docker Compose. Autentikasi memakai generator bawaan Rails 8. Tes memakai Minitest.

## Menjalankan

Cukup Docker (tanpa Ruby/Postgres di komputer):

```bash
docker compose up
```

Tunggu sampai muncul `Listening on http://0.0.0.0:3000`, lalu buka <http://localhost:3000>. Database dan data demo disiapkan otomatis. Bila port 3000 terpakai: `APP_PORT=3100 docker compose up`.

### Akun demo

Semua akun memakai kata sandi `siaga2026`. Di halaman masuk juga ada tombol akun demo sekali klik.

| Peran | Email |
|---|---|
| Guru mapel | `sari@siaga.test`, `budi@siaga.test`, `dewi@siaga.test`, `andi@siaga.test` |
| Guru piket | `rina@siaga.test`, `hendra@siaga.test` |
| Wakil kurikulum | `ratna@siaga.test` |
| Kepala sekolah | `bambang@siaga.test` |

### Menjalankan tes

```bash
docker compose run --rm app bash -c "RAILS_ENV=test bin/rails db:prepare && bin/rails test"
```

## Struktur singkat

```
app/controllers/concerns/   authentication.rb (bawaan Rails 8), authorization.rb (peran)
app/services/               Activations::Create/Plan/AssignPending/Broadcaster, Kits::Matcher, Duty::Assigner
app/models/                 school, user (enum role), period, school_class, subject, student,
                            lesson, duty_assignment, kit (transisi status), absence, activation, ...
app/controllers/kits_controller.rb  bank kit guru mapel (templat, PDF, filter)
app/controllers/curriculum/ CRUD wakil kurikulum (jadwal, kelas, mapel, jam pelajaran, piket)
app/assets/stylesheets/     tokens.css, base.css, layout.css, components.css (CSS murni)
logo/                       logo EDUVIA (SVG beranimasi, PNG transparan, favicon) + build.mjs
docs/                       rencana, keputusan, ide lanjutan
```

## Author & License

Created by Vassel Goleyu. Copyright (c) 2026 Vassel Goleyu. All rights reserved.
