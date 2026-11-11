# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Templat kit siap pakai supaya guru bisa menyiapkan kit dalam hitungan menit.
# Bukan tabel: tiga templat tetap, isinya hanya mengisi awal formulir.
class KitTemplate
  Template = Struct.new(:key, :name, :summary, :title, :duration_minutes, :instructions, :answer_key, keyword_init: true) do
    def attributes
      { title: title, duration_minutes: duration_minutes,
        supervisor_instructions: format(instructions, minutes: duration_minutes), answer_key: answer_key }
    end
  end

  COMMON = "Anda tidak perlu menguasai materi: cukup awasi dan kumpulkan hasil. " \
           "Setelah selesai, isi lembar kehadiran dan pengumpulan di aplikasi.".freeze

  ALL = [
    Template.new(
      key: "latihan_soal", name: "Latihan soal mandiri",
      summary: "Soal latihan dan kunci jawaban. Cocok untuk Matematika dan IPA.",
      title: "Latihan Soal Mandiri", duration_minutes: 35,
      instructions: "1. Bagikan lembar soal (lampiran PDF atau cetak).\n2. Siswa mengerjakan sendiri selama %<minutes>d menit, tanpa membuka HP.\n" \
                    "3. Kumpulkan lembar jawaban di akhir jam.\n#{COMMON}",
      answer_key: "No. 1: \nNo. 2: \nNo. 3: \nNo. 4: \nNo. 5: "
    ),
    Template.new(
      key: "baca_rangkum", name: "Membaca dan merangkum",
      summary: "Siswa membaca teks lalu menulis ringkasan. Cocok untuk bahasa dan IPS.",
      title: "Membaca dan Merangkum", duration_minutes: 35,
      instructions: "1. Bagikan teks bacaan (lampiran PDF atau cetak).\n2. Siswa membaca, lalu menulis ringkasan 5 kalimat dan 3 pertanyaan dari teks, selama %<minutes>d menit.\n" \
                    "3. Kumpulkan hasil tulisan di akhir jam.\n#{COMMON}",
      answer_key: "Poin penting yang perlu ada di ringkasan:\n- \n- \n- "
    ),
    Template.new(
      key: "proyek_mini", name: "Proyek mini",
      summary: "Tugas kreatif seperti peta konsep, poster, atau jawaban uraian.",
      title: "Proyek Mini Mandiri", duration_minutes: 40,
      instructions: "1. Jelaskan tugas pada lembar kerja (lampiran PDF atau cetak).\n2. Siswa mengerjakan sendiri selama %<minutes>d menit; diskusi pelan dengan teman sebangku diperbolehkan.\n" \
                    "3. Kumpulkan hasil di akhir jam.\n#{COMMON}",
      answer_key: "Kriteria penilaian:\n- Kelengkapan: \n- Ketepatan: \n- Kerapian: "
    )
  ].freeze

  def self.all = ALL
  def self.find(key) = ALL.find { |t| t.key == key.to_s }
end
