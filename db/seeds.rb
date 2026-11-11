# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Data demo. Aman dijalankan berulang (idempoten): tidak membuat duplikat dan tidak menimpa kata sandi.
school = School.find_or_create_by!(name: "SMP Negeri 3 Cerdas") { |s| s.active_days = [ 1, 2, 3, 4, 5 ] }

[
  [ "Sari Wulandari",    "sari",   "guru_mapel" ],
  [ "Budi Santoso",      "budi",   "guru_mapel" ],
  [ "Dewi Lestari",      "dewi",   "guru_mapel" ],
  [ "Andi Pratama",      "andi",   "guru_mapel" ],
  [ "Rina Marlina",      "rina",   "guru_piket" ],
  [ "Hendra Gunawan",    "hendra", "guru_piket" ],
  [ "Ratna Kusumawati",  "ratna",  "wakil_kurikulum" ],
  [ "Bambang Hartono",   "bambang", "kepala_sekolah" ]
].each do |name, handle, role|
  User.find_or_create_by!(email_address: "#{handle}@siaga.test") do |u|
    u.school = school
    u.name = name
    u.role = role
    u.password = Rails.configuration.x.demo_password
  end
end


# --- Jam pelajaran: 8 jam belajar + 2 istirahat (dikonfigurasi, bukan hard-code di aplikasi) ---
[
  [ 1, "07:00", "07:40" ], [ 2, "07:40", "08:20" ], [ 3, "08:20", "09:00" ],
  [ 4, "09:00", "09:20", true ],
  [ 5, "09:20", "10:00" ], [ 6, "10:00", "10:40" ], [ 7, "10:40", "11:20" ],
  [ 8, "11:20", "11:40", true ],
  [ 9, "11:40", "12:20" ], [ 10, "12:20", "13:00" ]
].each do |number, starts, ends, recess|
  Period.find_or_create_by!(school: school, number: number) do |p|
    p.starts_at = starts
    p.ends_at = ends
    p.recess = recess || false
    p.label = "Istirahat" if recess
  end
end

# --- Mapel, kelas, siswa ---
subjects = [
  [ "Matematika", "MTK" ], [ "IPA", "IPA" ], [ "Bahasa Indonesia", "BIN" ], [ "Bahasa Inggris", "BIG" ], [ "IPS", "IPS" ]
].to_h { |name, code| [ code, Subject.find_or_create_by!(school: school, code: code) { |x| x.name = name } ] }

classes = [ [ "VII A", 7 ], [ "VII B", 7 ], [ "VII C", 7 ], [ "VIII A", 8 ], [ "VIII B", 8 ], [ "IX A", 9 ] ]
  .to_h { |name, grade| [ name, SchoolClass.find_or_create_by!(school: school, name: name) { |c| c.grade_level = grade } ] }

student_names = %w[
  Aditya Bagas Citra Dinda Eko Farah Galih Hana Indra Jihan Kevin Laras Maya Naufal Olivia Putra Qori Rafi Salsa Tegar
  Umar Vina Wahyu Xena Yoga Zahra Alif Bunga Cahya Dafa Elok Fikri Gita Hasan Intan Joko Kirana Lintang Mawar Nanda
].each_slice(7).to_a
classes.values.each_with_index do |klass, i|
  student_names[i].each_with_index do |first, n|
    Student.find_or_create_by!(school_class: klass, roll_number: n + 1) { |st| st.name = "#{first} #{%w[Pratama Sari Wijaya Utami Nugroho Lestari Permana][(i + n) % 7]}" }
  end
end

# --- Jadwal seminggu ---
teachers = [
  [ "sari", %w[MTK] ], [ "budi", %w[IPA] ], [ "dewi", %w[BIN BIG] ], [ "andi", %w[IPS] ]
].map { |handle, codes| [ User.find_by!(email_address: "#{handle}@siaga.test"), codes ] }

teaching = school.periods.teaching.ordered.to_a
school.active_days.sort.each do |day|
  classes.values.each_with_index do |klass, c|
    teaching.each_with_index do |period, i|
      slot = (c + i + day) % 8 # nilai berbeda untuk tiap kelas pada jam yang sama => guru tidak pernah bentrok
      next if slot >= teachers.size

      teacher, codes = teachers[slot]
      Lesson.find_or_create_by!(school_class: klass, day_of_week: day, period: period) do |l|
        l.teacher = teacher
        l.subject = subjects.fetch(codes[(c + day) % codes.size]) # tiap kelas mendapat semua mapel guru
      end
    end
  end
end

# --- 10 kit siaga ---
TOPICS = {
  "MTK" => [ "Latihan Soal Pecahan dan Desimal", "Kerjakan soal nomor 1-10 pada lembar kerja secara mandiri. Boleh memakai kalkulator." ],
  "IPA" => [ "Membaca dan Merangkum: Sistem Pencernaan", "Baca teks, lalu buat ringkasan 5 kalimat dan 3 pertanyaan dari teks." ],
  "BIN" => [ "Menulis Paragraf Deskripsi", "Tulis paragraf deskripsi tentang tempat favorit minimal 8 kalimat." ],
  "BIG" => [ "Reading Comprehension: My Daily Routine", "Read the text and answer the 8 questions in your notebook." ],
  "IPS" => [ "Peta Konsep: Interaksi Sosial", "Buat peta konsep interaksi sosial dengan minimal 3 contoh dari lingkungan sekitar." ]
}.freeze
SAMPLE_PDF = File.binread(Rails.root.join("db/seed_files/lembar-kerja-contoh.pdf")).freeze
SUPERVISOR = "Bagikan lembar kerja, pastikan siswa duduk tenang dan mengerjakan sendiri selama %<d>d menit. " \
             "Anda tidak perlu menguasai materi: cukup awasi dan kumpulkan hasil di akhir jam. Isi lembar kehadiran dan pengumpulan di aplikasi."

[
  [ "sari", "MTK", "VII A", :disiapkan ], [ "sari", "MTK", "VII B", :terpakai ], [ "sari", "MTK", "VIII A", :disiapkan ], [ "sari", "MTK", "IX A", :disiapkan ],
  [ "budi", "IPA", "VII A", :disiapkan ], [ "budi", "IPA", "VII B", :disiapkan ],
  [ "dewi", "BIN", "VII A", :disiapkan ], [ "dewi", "BIN", "VIII A", :terpakai ], [ "dewi", "BIG", "VII A", :disiapkan ],
  [ "andi", "IPS", "VII A", :disiapkan ]
].each do |handle, code, class_name, status|
  title, task = TOPICS.fetch(code)
  duration = 30 + (code.sum % 3) * 5 # 30, 35, atau 40 menit
  Kit.find_or_create_by!(user: User.find_by!(email_address: "#{handle}@siaga.test"), subject: subjects.fetch(code), school_class: classes.fetch(class_name)) do |k|
    k.title = title
    k.duration_minutes = duration
    k.supervisor_instructions = "#{task} #{format(SUPERVISOR, d: duration)}"
    k.answer_key = "Kunci jawaban tersedia untuk guru piket. Periksa jawaban siswa dengan merujuk petunjuk pada lembar kerja."
    k.status = status
    k.times_used = status == :terpakai ? 1 : 0
    k.last_used_at = 10.days.ago if status == :terpakai
  end.tap do |kit|
    next if kit.worksheet.attached?
    kit.worksheet.attach(io: StringIO.new(SAMPLE_PDF), filename: "lembar-kerja-#{code.downcase}-#{class_name.parameterize}.pdf", content_type: "application/pdf")
  end
end

# --- Penugasan piket: 3 hari kerja pertama dua guru, 3 berikutnya satu guru, sisanya belum ada ---
rina = User.find_by!(email_address: "rina@siaga.test")
hendra = User.find_by!(email_address: "hendra@siaga.test")
duty_dates = (Date.current..Date.current + 14).select { |d| school.active_days.include?(d.cwday) }
duty_dates.each_with_index do |date, i|
  DutyAssignment.find_or_create_by!(user: rina, date: date) if i < 6
  DutyAssignment.find_or_create_by!(user: hendra, date: date) if i < 3
end

puts "Seed selesai: #{School.count} sekolah, #{User.count} pengguna, #{SchoolClass.count} kelas, #{Subject.count} mapel, " \
     "#{Lesson.count} jadwal, #{Kit.count} kit, #{DutyAssignment.count} penugasan piket."
