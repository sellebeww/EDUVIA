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
| D15 | 2026-11-11 | Seed Fase 1 hanya sekolah + 8 pengguna. Kelas, mapel, jadwal, dan kit ditambahkan ke seed pada fase yang membuat modelnya (2 dan 3) | Brief meminta seed lengkap di Fase 1, tetapi modelnya baru ada di Fase 2 | Rendah |
| D16 | 2026-11-11 | Konfigurasi Solid Cable (database `cable`) dipindah dari Fase 1 ke Fase 4 | Baru dibutuhkan saat Turbo Streams dipakai; menghindari konfigurasi yang belum teruji | Rendah |
| D17 | 2026-11-11 | Rails yang terpasang 8.1.4 (generator `~> 8.0`), tambah gem `rails-i18n` untuk pesan bahasa Indonesia | Pesan validasi dan nama bulan/hari berbahasa Indonesia tanpa menulis ulang | Rendah |
| D18 | 2026-11-11 | Tombol "Akun demo" di halaman masuk hanya muncul di `development`; kata sandi demo di `config.x.demo_password` | Juri bisa masuk sekali klik; tidak aktif di lingkungan lain | Rendah |
| D19 | 2026-11-11 | Port host dapat diubah lewat `APP_PORT` (bawaan 3000); database tidak dibuka ke host | Menghindari bentrok port di komputer juri | Rendah |
| D20 | 2026-11-11 | Kolom `periods.break` diberi nama `recess` | `break` adalah kata kunci Ruby, rawan membingungkan | Rendah |
| D21 | 2026-11-11 | Batas tanggal Absence (hari ini s/d +7 hari) dijaga oleh `Activations::Create`, bukan validasi model | Model harus tetap bisa menyimpan data historis (seed laporan bulan lalu, impor) | Rendah |
| D22 | 2026-11-11 | Kolom `time` tidak dikonversi zona waktu (`time_zone_aware_types = [:datetime]`) | Jam pelajaran adalah jam dinding lokal; konversi membuat 07.00 terbaca 14.00 (ditemukan oleh tes) | Rendah |
| D23 | 2026-11-11 | Tanpa CRUD siswa di MVP; siswa diisi lewat seed | Brief hanya meminta CRUD jadwal, kelas, mapel, dan piket | Rendah |
| D24 | 2026-11-11 | Seed memakai rumus jadwal tanpa bentrok guru; tiap kelas mendapat 4 jam per hari dan semua 5 mapel | Data demo realistis tetapi konsisten dengan validasi | Rendah |
| D25 | 2026-11-11 | Menghapus hari aktif sekolah ditolak bila hari itu masih punya jadwal | Mencegah jadwal yatim di hari yang tidak aktif | Rendah |
| D26 | 2026-11-11 | Formulir kit memilih "Kelas dan mapel" dari satu daftar berisi pasangan yang benar-benar diajar guru (diambil dari jadwal) | Mengurangi isian, mustahil memilih kombinasi tak valid, mempercepat target < 3 menit | Rendah |
| D27 | 2026-11-11 | Templat kit diisi dari server lewat parameter URL (`?template=`), tanpa Stimulus/JS | Lebih ringan, berfungsi tanpa JavaScript, mudah dites | Rendah |
| D28 | 2026-11-11 | Lampiran PDF dicek tipe, ukuran (≤ 5 MB), dan magic byte `%PDF-`; unduhan lewat aksi `kits#worksheet` (bukan URL Active Storage publik) | Content-type bisa dipalsukan (Marcel tidak mendeteksi teks biasa); hak akses harus dicek di setiap unduhan | Rendah |
| D29 | 2026-11-11 | Kit berstatus `aktif` tidak bisa diubah atau dihapus; kit yang pernah punya aktivasi tidak bisa dihapus | Kit yang sedang dipakai di kelas tidak boleh berubah di tengah jalan; riwayat laporan terjaga | Rendah |
| D30 | 2026-11-11 | Halaman bank kit menyarankan kelas yang belum punya kit dengan tautan siap isi | Mendorong kesiapsiagaan, dan membuat kit pertama cukup 3 langkah | Rendah |
| D31 | 2026-11-11 | Tanpa paginasi di bank kit | Jumlah kit per guru kecil (puluhan); dicatat di Known limitations | Rendah |
| D32 | 2026-11-11 | Pratinjau dampak memakai GET + Turbo Frame (`absences#new`), bukan `POST preview` seperti di PLAN §3; tidak ada halaman `activations` terpisah, daftar aktivasi hidup di dashboard wakil kurikulum | URL pratinjau bisa di-refresh dan dibagikan; satu halaman lebih sedikit | Rendah |
| D33 | 2026-11-11 | `Activations::Plan` (tanpa menulis) dipakai bersama oleh pratinjau dan `Create` | Yang dilihat wakil kurikulum sama dengan yang akan terjadi | Rendah |
| D34 | 2026-11-11 | Siaran Turbo Streams memakai `replace` seluruh daftar (bukan `prepend` satu kartu) | Urutan jam dan pengelompokan tanggal selalu benar; tidak ada kartu ganda atau basi | Rendah |
| D35 | 2026-11-11 | Siaran dikirim di luar transaksi (setelah commit) dan kegagalan siaran hanya dicatat di log | Aktivasi yang sudah tersimpan tidak boleh batal karena kabel putus | Rendah |
| D36 | 2026-11-11 | Penugasan piket yang sudah menerima kit aktif tidak bisa dihapus; menambah piket pada tanggal yang punya aktivasi "menunggu" langsung memberikannya (`AssignPending`) | Mencegah kartu yatim; menutup kasus "guru piket belum ditugaskan" | Rendah |
| D37 | 2026-11-11 | Pembagian guru piket: utamakan yang bebas pada jam itu, lalu beban terkecil; bila semua sibuk, tetap ditugaskan dengan peringatan `concurrent_conflict` | Kelas kosong tidak boleh dibiarkan tanpa pengawas | Rendah |
| D38 | 2026-11-11 | Helper stub tes dibuat sendiri (`stub_method`) dan helper Turbo di-include eksplisit | Minitest 6 membuang `Object#stub`; include otomatis turbo-rails bergantung urutan load (tes sempat tidak stabil) | Rendah |
| D39 | 2026-11-11 | Tiap baris lembar adalah Turbo Frame + formulir kecil yang disimpan otomatis (Stimulus `autosave`, ±15 baris JS); jawaban berupa Turbo Stream yang mengganti baris dan ringkasan. Tanpa JS tersedia tombol Simpan (`<noscript>`) dan redirect | Sesuai brief (simpan inline), ringan, tetap bisa dipakai tanpa JavaScript | Rendah |
| D40 | 2026-11-11 | Setelah "Selesai", lembar hanya bisa dibaca (penulisan ditolak 409); hasil selalu kembali ke guru yang berhalangan (= pemilik kit) | Hasil yang sudah dikirim ke guru tidak boleh berubah diam-diam | Rendah |
| D41 | 2026-11-11 | Daftar guru piket tetap menampilkan aktivasi yang sudah selesai hari itu ("Lihat hasil") | Guru piket bisa meninjau pekerjaannya; hilang otomatis besok | Rendah |
| D42 | 2026-11-11 | Laporan: jam kosong dihitung menurut tanggal ketidakhadiran; "tertangani kit" = ada kit DAN selesai; semua angka dari 4 query GROUP BY | Definisi tunggal yang tertulis di halaman; bebas N+1 | Rendah |
| D43 | 2026-11-11 | `/reports` mengarah ke bulan berjalan; bulan tak valid 404; bulan depan tidak ditautkan | Alamat laporan bisa dibagikan dan dibookmark | Rendah |
| D44 | 2026-11-11 | Seed riwayat: dua bulan lalu tanpa kit (semua mode cadangan), bulan lalu memakai 5 kit berstatus "terpakai"; hanya dibuat sekali | Laporan punya tren yang jujur dan konsisten dengan status kit; 5 kit "terpakai" juga menjadi bahan demo pakai ulang | Rendah |
