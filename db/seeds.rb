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

puts "Seed selesai: #{School.count} sekolah, #{User.count} pengguna."
