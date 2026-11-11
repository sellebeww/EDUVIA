# Copyright (c) 2026 Vassel Goleyu. All rights reserved.

module ApplicationHelper
  # Menu navigasi per peran: [[label, path], ...]
  def nav_items_for(user)
    case user.role
    when "guru_mapel" then [ [ "Bank Kit", kits_path ] ]
    when "guru_piket" then [ [ "Kit Hari Ini", duty_root_path ] ]
    when "wakil_kurikulum" then [ [ "Jam Kosong", curriculum_root_path ], [ "Laporan", reports_path ] ]
    when "kepala_sekolah" then [ [ "Laporan Bulanan", reports_path ] ]
    else []
    end
  end
end
