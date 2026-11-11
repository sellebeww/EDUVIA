# Skrip demo 3 menit untuk juri

Tujuan: memperlihatkan alur utama, **menyiapkan kit → satu tombol → guru piket menerima langsung → hasil kembali ke guru → laporan**, tanpa kendala teknis.

## Persiapan (sekali, ±2 menit sebelum demo)

```bash
docker compose down -v        # data bersih (abaikan bila baru pertama kali)
docker compose up             # tunggu: "Listening on http://0.0.0.0:3000" (±1 menit pertama)
```

- Buka <http://localhost:3000>. Bila port 3000 terpakai: `APP_PORT=3100 docker compose up`.
- Bila dibuka lewat nama komputer (bukan `localhost`/IP): `ALLOWED_HOSTS=nama-komputer docker compose up`.
- Siapkan **tiga jendela browser** berdampingan (jendela biasa + jendela penyamaran + browser lain, supaya sesi tidak bertabrakan):

| Jendela | Peran | Akun (kata sandi `siaga2026`) | Buka dulu |
|---|---|---|---|
| A | Wakil kurikulum | `ratna@siaga.test` | `/curriculum` |
| B | Guru piket | `rina@siaga.test` | `/duty` (biarkan terbuka) |
| C | Guru mapel | `sari@siaga.test` | `/kits` (biarkan terbuka) |

Di halaman masuk ada tombol **Akun demo**: satu klik langsung masuk. Pastikan penanda hijau **LANGSUNG** terlihat di jendela B dan C (artinya koneksi realtime aktif).

> Demo jatuh di akhir pekan? Tidak masalah. Formulir tandai guru berhalangan otomatis memilih **hari kerja terdekat**, dan data seed menugaskan guru piket pada hari kerja terdekat.

## Naskah (±3 menit)

### 0:00 – 0:25 · Masalah dan idenya
*Jendela masuk (logo beranimasi).* "Saat guru berhalangan, kelas jadi jam kosong. Guru piket hanya bisa memberi tugas mencatat. Siaga Kelas membalik urutannya: **guru menyiapkan kit lebih dulu**, jadi saat hari-H cukup satu tombol."

### 0:25 – 1:00 · Kesiapsiagaan: menyiapkan kit < 3 menit (jendela C, Sari)
1. Tunjuk kartu "Belum punya kit (2 kelas)". "Sistem tahu kelas mana yang belum aman."
2. Klik salah satu chip. Formulir **sudah terisi templat** (judul, durasi, petunjuk untuk pengawas non-ahli).
3. Klik **Simpan**. Selesai dalam 3 langkah. (Opsional: tunjukkan unggah PDF dan penolakan berkas palsu.)

### 1:00 – 1:50 · Satu tombol (jendela A, Ratna)
1. **Tandai guru berhalangan** → pilih *Sari Wulandari* → tanggal sudah terisi → **Lihat dampak**.
2. Jelaskan pratinjau: tiap jam terdampak, kit mana yang cocok, guru piket siapa. Tunjuk **kasus tepi**: *mode cadangan* bila tidak ada kit, **pakai ulang** bila kit sudah terpakai, peringatan bila guru piket yang sama menangani dua kelas pada jam yang sama.
3. Klik **Aktifkan N kelas sekarang**.
4. **Langsung lihat jendela B**: slip jam muncul **tanpa refresh**, ada toast "Kit baru masuk", dan judul tab berubah "(3) Kit Hari Ini". Dashboard Ratna menampilkan strip cakupan kit.

### 1:50 – 2:30 · Guru piket mengawasi (jendela B, Rina)
1. Buka slip → tunjukkan **petunjuk pengawas**, **unduh PDF**, **kunci jawaban**.
2. Lembar kehadiran: klik **Tidak hadir** pada satu siswa, ketik nilai. Centang kecil muncul dan ringkasan berubah: **tersimpan otomatis per baris**.
3. Klik **Selesai dan kirim hasil ke guru**.

### 2:30 – 3:00 · Hasil kembali ke guru, laporan untuk kepala sekolah
1. **Jendela C** (Sari): toast "Hasil masuk" dan kartu **Hasil terbaru** muncul langsung; kit berpindah ke "Sudah terpakai".
2. Masuk sebagai `bambang@siaga.test` (kepala sekolah) → **Laporan Bulanan** (pilih bulan lalu): jumlah jam kosong, % tertangani kit, tren 6 bulan, penyebab. "Dua bulan lalu belum ada kit (0%), bulan lalu 27%." (Data riwayat adalah **data seed**, bukan data sekolah nyata.)

## Jika juri bertanya (kasus tepi, 30 detik masing-masing)

| Pertanyaan | Peragaan |
|---|---|
| Bagaimana kalau tidak ada guru piket? | Di jendela A pilih tanggal ±hari kerja ke-7 (belum ada penugasan) → pratinjau menandai "Belum ditugaskan". Setelah aktivasi, buka **Piket**, tugaskan guru: kartu langsung terkirim ke guru itu. |
| Dua kelas kosong bersamaan? | Aktifkan dua guru berbeda pada tanggal yang sama: pratinjau membagi ke guru piket berbeda, atau memberi peringatan bila hanya ada satu. |
| Klik dua kali? | Tekan **Aktifkan** lagi: pesan "sudah diaktifkan sebelumnya", tanpa data ganda (dijaga transaksi + indeks unik + kunci). |
| Jadwal berbeda antar sekolah? | **Data Sekolah**: hari aktif dan jam pelajaran bisa diubah, bukan hard-code. |
| Aman? | `docs/DECISIONS.md` dan bagian Keamanan di README. Semua halaman dicek hak aksesnya; ada tes yang menyapu seluruh rute. |

## Mengatur ulang dan masalah umum

| Gejala | Penyebab / tindakan |
|---|---|
| Ingin mulai dari nol | `docker compose down -v && docker compose up` (seed otomatis) |
| `port is already allocated` | `APP_PORT=3100 docker compose up` |
| 403 "Blocked hosts" | `ALLOWED_HOSTS=nama-host docker compose up` |
| Penanda tetap abu-abu "Menyambung" | WebSocket diblokir proxy/antivirus. Fitur tetap jalan, muat ulang halaman untuk melihat pembaruan. |
| "Terlalu banyak percobaan" saat masuk | Batas percobaan per akun (10 per 3 menit). Tunggu sebentar, atau restart aplikasi. |
| Slip tidak muncul di jendela B | Pastikan masuk sebagai guru piket yang ditugaskan hari itu (Rina dan Hendra). Daftar bergantung pada pembagian beban. |
| Logo masuk kosong sebentar | Itu animasi pembuka (±2 detik). |
| Pembaruan live terasa lambat (>1 detik) | Mesin sedang sibuk (mis. banyak container lain). Tutup proses berat sebelum demo. Perilaku tetap benar. |
