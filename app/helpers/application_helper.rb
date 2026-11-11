# Copyright (c) 2026 Vassel Goleyu. All rights reserved.

module ApplicationHelper
  # Menu navigasi per peran: [[label, path], ...]
  def nav_items_for(user)
    case user.role
    when "guru_mapel" then [ [ "Bank Kit", kits_path ], [ "Hasil", results_path ] ]
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

  # "Hari ini · Rabu, 11 November 2026", "Besok · ...", atau tanggal biasa.
  def date_heading(date)
    full = l(date, format: "%A, %d %B %Y")
    case date
    when Date.current then "Hari ini · #{full}"
    when Date.current + 1 then "Besok · #{full}"
    else full
    end
  end

  def activation_status_badge(activation)
    label, css, icon_name = { selesai: [ "Selesai", "terpakai", "check" ], aktif: [ "Aktif", "aktif", "bell" ], menunggu_piket: [ "Menunggu piket", "warn", "clock" ] }.fetch(activation.status)
    tag.span(safe_join([ icon(icon_name, size: 12), label ]), class: "badge badge--status-#{css}")
  end

  # Menu aktif juga untuk halaman turunan (mis. /kits/3 -> Bank Kit). Bila beberapa menu cocok
  # (mis. /curriculum dan /curriculum/lessons), hanya yang paling spesifik (terpanjang) yang aktif.
  def nav_current?(path, items = nav_items_for(current_user))
    matches = items.map(&:last).select { |candidate| request.path == candidate || request.path.start_with?("#{candidate}/") }
    matches.max_by(&:length) == path
  end

  # "Selasa 11 Nov": tanggal singkat untuk daftar hasil.
  def short_date(date) = l(date, format: "%a, %d %b %Y")

  # Persentase bulat; "-" bila penyebut nol.
  def percent_of(part, whole) = whole.to_i.zero? ? "-" : "#{(part * 100.0 / whole).round}%"
end
