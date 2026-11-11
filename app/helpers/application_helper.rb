# Copyright (c) 2026 Vassel Goleyu. All rights reserved.

module ApplicationHelper
  # Menu navigasi per peran: [[label, path], ...]
  def nav_items_for(user)
    case user.role
    when "guru_mapel" then [ [ "Bank Kit", kits_path ] ]
    when "guru_piket" then [ [ "Kit Hari Ini", duty_root_path ] ]
    when "wakil_kurikulum"
      [ [ "Jam Kosong", curriculum_root_path ], [ "Jadwal", curriculum_lessons_path ], [ "Piket", curriculum_duty_assignments_path ],
        [ "Data Sekolah", curriculum_school_path ], [ "Laporan", reports_path ] ]
    when "kepala_sekolah" then [ [ "Laporan Bulanan", reports_path ] ]
    else []
    end
  end

  # Nama hari Indonesia dari angka hari ISO (1=Senin .. 7=Minggu).
  def day_name(cwday)
    I18n.t("date.day_names")[cwday % 7]
  end

  def error_messages_for(record)
    return if record.errors.empty?
    render "shared/errors", record: record
  end
end
