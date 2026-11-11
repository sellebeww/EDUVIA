# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class Reports::MonthlyTest < ActiveSupport::TestCase
  OCT = Date.new(2026, 10, 1)

  def record(teacher:, date:, lesson:, reason: "sakit", kit: nil, completed: true, reused: false, absence: nil)
    absence ||= Absence.find_by(teacher: teacher, date: date) || Absence.create!(teacher: teacher, date: date, reason: reason, created_by: users(:wakil_kurikulum))
    Activation.create!(absence: absence, lesson: lesson, kit: kit, invigilator: users(:guru_piket), reused: reused,
                       activated_at: date.in_time_zone.change(hour: 7), completed_at: (completed ? date.in_time_zone.change(hour: 12) : nil))
  end

  setup do
    # Oktober 2026: Senin 5, 12, 19, 26; Selasa 6, 13, 20, 27.
    record(teacher: users(:guru_mapel), date: Date.new(2026, 10, 5), lesson: lessons(:senin_jam1_7a), kit: kits(:mtk_7a_siap))
    record(teacher: users(:guru_mapel), date: Date.new(2026, 10, 5), lesson: lessons(:senin_jam2_8a))
    record(teacher: users(:guru_mapel_dua), date: Date.new(2026, 10, 12), reason: "izin", lesson: lessons(:senin_jam2_7a), kit: kits(:ipa_7a_siap), reused: true)
    record(teacher: users(:guru_mapel_dua), date: Date.new(2026, 10, 20), reason: "dinas", lesson: lessons(:selasa_jam1_8a), completed: false)
    # September (bulan sebelumnya) dan November (bulan sesudahnya)
    record(teacher: users(:guru_mapel), date: Date.new(2026, 9, 7), lesson: lessons(:senin_jam2_8a))
    record(teacher: users(:guru_mapel), date: Date.new(2026, 11, 2), lesson: lessons(:senin_jam2_8a))
  end

  def report(month = OCT) = Reports::Monthly.new(school: schools(:smp), month: month)

  test "total, kit, tertangani, belum selesai, dan pakai ulang" do
    t = report.totals
    assert_equal 4, t.total
    assert_equal 2, t.with_kit
    assert_equal 2, t.handled
    assert_equal 2, t.no_kit
    assert_equal 1, t.unfinished
    assert_equal 1, t.reused
    assert_equal 50, t.handled_percent
  end

  test "tertangani kit mensyaratkan kit DAN sudah selesai" do
    kit_but_open = record(teacher: users(:guru_mapel), date: Date.new(2026, 10, 12), lesson: lessons(:senin_jam1_7a), kit: kits(:mtk_7a_terpakai), completed: false)
    t = report.totals
    assert_equal 5, t.total
    assert_equal 3, t.with_kit
    assert_equal 2, t.handled, "kit yang belum diselesaikan tidak dihitung tertangani"
    assert kit_but_open.persisted?
  end

  test "batas bulan: hanya tanggal dalam bulan itu" do
    assert_equal 1, report(Date.new(2026, 9, 1)).totals.total
    assert_equal 1, report(Date.new(2026, 11, 1)).totals.total
    assert_equal 4, report(Date.new(2026, 10, 17)).totals.total, "tanggal mana pun dalam bulan dinormalisasi ke awal bulan"
  end

  test "per minggu: hari 1-7, 8-14, 15-21, 22-28, 29-31" do
    weekly = report.weekly
    assert_equal 5, weekly.size
    assert_equal [ [ 1, 2, 1 ], [ 2, 1, 1 ], [ 3, 1, 0 ], [ 4, 0, 0 ], [ 5, 0, 0 ] ], weekly.map { |w| [ w[:week], w[:total], w[:handled] ] }
  end

  test "jumlah minggu mengikuti panjang bulan" do
    assert_equal 4, report(Date.new(2026, 2, 1)).weekly.size # Februari 2026: 28 hari
    assert_equal 5, report(Date.new(2026, 3, 1)).weekly.size
  end

  test "penyebab terbanyak lebih dulu dengan label Indonesia" do
    assert_equal [ [ "Sakit", 2 ], [ "Izin", 1 ], [ "Dinas luar", 1 ] ].first, report.reasons.first
    assert_equal({ "Sakit" => 2, "Izin" => 1, "Dinas luar" => 1 }, report.reasons.to_h)
  end

  test "tren enam bulan berakhir di bulan yang dilihat, bulan kosong bernilai nol" do
    trend = report.trend
    assert_equal 6, trend.size
    assert_equal Date.new(2026, 5, 1), trend.first[:month]
    assert_equal OCT, trend.last[:month]
    assert_equal [ 0, 0, 0, 0, 1, 4 ], trend.map { |t| t[:total] }.last(6).then { |a| [ a[0], a[1], a[2], a[3], a[4], a[5] ] }
    assert_equal 50, trend.last[:percent]
    assert_equal 0, trend.first[:percent]
  end

  test "perubahan dari bulan sebelumnya" do
    assert_equal 300, report.change_from_previous # 1 -> 4
    assert_nil report(Date.new(2026, 9, 1)).change_from_previous # Agustus kosong
  end

  test "bulan tanpa data: kosong, tanpa galat" do
    empty = report(Date.new(2026, 1, 1))
    assert empty.empty?
    assert_equal 0, empty.totals.handled_percent
    assert_equal [ 0, 0, 0, 0, 0 ], empty.weekly.map { |w| w[:total] }
    assert_empty empty.reasons
    assert_nil empty.change_from_previous
  end

  test "data sekolah lain tidak ikut terhitung" do
    other = Lesson.create!(school_class: school_classes(:kelas_lain), subject: subjects(:mapel_lain), teacher: users(:guru_lain), period: periods(:jam_lain), day_of_week: 1)
    record(teacher: users(:guru_lain), date: Date.new(2026, 10, 5), lesson: other)
    assert_equal 4, report.totals.total
    assert_equal 1, Reports::Monthly.new(school: schools(:lain), month: OCT).totals.total
  end

  test "jumlah query tetap kecil (tanpa N+1): 4 query untuk seluruh laporan" do
    r = report
    assert_equal 4, count_queries { r.totals; r.weekly; r.reasons; r.trend; r.change_from_previous }
  end
end
