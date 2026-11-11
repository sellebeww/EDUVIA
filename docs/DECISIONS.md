# Catatan Keputusan

Keputusan yang murah diubah diputuskan langsung dan dicatat di sini. Yang mahal diubah ditanyakan dulu (lihat PLAN.md §11).

| # | Tanggal | Keputusan | Alasan | Biaya mengubah |
|---|---|---|---|---|
| D1 | 2026-11-11 | Ruby/Rails hanya dijalankan di Docker | Host memakai Ruby 2.6 tanpa Rails/psql | Rendah |
| D2 | 2026-11-11 | Tambah tabel `School` dan `Period` | Jam pelajaran dan hari aktif harus bisa dikonfigurasi per sekolah | Sedang (diputuskan sebelum migrasi pertama) |
| D3 | 2026-11-11 | Tambah tabel `DutyAssignment` | Brief butuh "penugasan guru piket" tapi tanpa tabel | Rendah |
| D4 | 2026-11-11 | `Kit.phase` diturunkan dari `SchoolClass.grade_level` | Mencegah kit salah fase | Rendah |
| D5 | 2026-11-11 | `Activation.kit_id` nullable + `warning_codes` | Jam kosong tanpa kit tetap tercatat dan tampil sebagai mode cadangan | Rendah |
| D6 | 2026-11-11 | Templat kit berupa PORO, bukan tabel | Tiga templat tetap, tidak perlu CRUD | Rendah |
| D7 | 2026-11-11 | Active Job `:async`, tanpa Solid Queue/Cache (`--skip-solid`) | Lebih ringan; hanya Solid Cable yang dibutuhkan | Rendah |
| D8 | 2026-11-11 | Demo berjalan sebagai `RAILS_ENV=development` | Menghindari konfigurasi SSL/secret produksi bagi juri | Rendah |
| D9 | 2026-11-11 | Kode berbahasa Inggris, UI berbahasa Indonesia, enum domain berbahasa Indonesia | Mengikuti nama di brief | Rendah |
| D10 | 2026-11-11 | Aktivasi boleh untuk hari ini sampai 7 hari ke depan | Wakur sering tahu guru berhalangan sehari sebelumnya; juga membuat demo aman di akhir pekan | Rendah |
| D11 | 2026-11-11 | Kit berstatus `aktif` dilewati saat pencocokan; jam ganda mapel yang sama memakai kit berikutnya atau mode cadangan | Satu kit tidak boleh aktif di dua tempat | Rendah |
| D12 | 2026-11-11 | Guru piket boleh melihat kunci jawaban | Pengawas non-ahli perlu mengoreksi | Rendah |
| D13 | 2026-11-11 | Brand EDUVIA, produk Siaga Kelas, tampil bersama di header | Logo yang diberikan bertuliskan EDUVIA | Rendah |
| D14 | 2026-11-11 | Logo dibuat sebagai SVG hasil `logo/build.mjs` dengan huruf sebagai path | Tanpa ketergantungan font, mudah dianimasikan | Rendah |
