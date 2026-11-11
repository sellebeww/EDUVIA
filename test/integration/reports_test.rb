# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class ReportsTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.zone.local(2026, 11, 9, 8, 0)
    make = lambda do |teacher, date, lesson, kit: nil, completed: true, reason: "sakit"|
      absence = Absence.find_by(teacher: teacher, date: date) || Absence.create!(teacher: teacher, date: date, reason: reason, created_by: users(:wakil_kurikulum))
      Activation.create!(absence: absence, lesson: lesson, kit: kit, invigilator: users(:guru_piket), activated_at: date.in_time_zone.change(hour: 7), completed_at: (completed ? date.in_time_zone.change(hour: 12) : nil))
    end
    make.call(users(:guru_mapel), Date.new(2026, 10, 5), lessons(:senin_jam1_7a), kit: kits(:mtk_7a_siap))
    make.call(users(:guru_mapel), Date.new(2026, 10, 5), lessons(:senin_jam2_8a))
    make.call(users(:guru_mapel_dua), Date.new(2026, 10, 12), lessons(:senin_jam2_7a), kit: kits(:ipa_7a_siap), reason: "izin")
    make.call(users(:guru_mapel_dua), Date.new(2026, 10, 20), lessons(:selasa_jam1_8a), completed: false, reason: "dinas")
    make.call(users(:guru_mapel), Date.new(2026, 9, 7), lessons(:senin_jam2_8a))
  end

  test "/reports mengarah ke bulan berjalan" do
    log_in_as :kepala_sekolah
    get reports_path
    assert_redirected_to report_path("2026-11")
  end

  test "kepala sekolah melihat angka, grafik, dan definisi" do
    log_in_as :kepala_sekolah
    get report_path("2026-10")
    assert_response :success
    assert_select "h1", "Laporan Bulanan"
    assert_select ".stat", /4\s*Jam kosong/m
    assert_select ".stat", /50%\s*Tertangani kit/m
    assert_select ".stat", /2 dari 4 jam/
    assert_select ".stat", /naik 300% dari bulan lalu/
    assert_select ".vbar", 6
    assert_select ".vbar--current[aria-label*='Oktober 2026: 4 jam kosong, 50 persen']"
    assert_select ".hbar__label", text: "Minggu 1"
    assert_select ".hbar__label", text: "Sakit"
    assert_select ".hbar__label", text: "Dinas luar"
    assert_select ".report-note", /Tertangani kit/
  end

  test "navigasi bulan: sebelumnya selalu ada, berikutnya hanya bila bukan bulan berjalan" do
    log_in_as :wakil_kurikulum
    get report_path("2026-10")
    assert_select "nav[aria-label='Pilih bulan'] a", text: /Sep 2026/
    assert_select "nav[aria-label='Pilih bulan'] a", text: /Nov 2026/
    get report_path("2026-11")
    assert_select "nav[aria-label='Pilih bulan'] a", text: /Okt 2026/
    assert_select "nav[aria-label='Pilih bulan'] a", text: /Des 2026/, count: 0
  end

  test "bulan tanpa data menampilkan keadaan kosong yang ramah" do
    log_in_as :kepala_sekolah
    get report_path("2026-11")
    assert_response :success
    assert_select ".empty-state__title", "Belum ada jam kosong pada bulan ini"
  end

  test "parameter bulan tidak valid: 404, bukan 500" do
    log_in_as :kepala_sekolah
    [ "2026-13", "2026-00", "abc", "2026-1", "20261", "2026-10-01" ].each do |bad|
      get report_path(bad)
      assert_response :not_found, bad
    end
  end

  test "peran lain tidak boleh melihat laporan" do
    %i[guru_mapel guru_piket].each do |role|
      log_in_as role
      get report_path("2026-10")
      assert_response :forbidden, role
      delete session_path
    end
  end

  test "kepala sekolah hanya punya satu menu: laporan" do
    log_in_as :kepala_sekolah
    get report_path("2026-10")
    assert_select ".main-nav a", 1
    get kits_path
    assert_response :forbidden
    get curriculum_root_path
    assert_response :forbidden
  end

  test "laporan tidak N+1: jumlah query sama walau data bertambah" do
    log_in_as :kepala_sekolah
    get report_path("2026-10") # pemanasan
    before = count_queries { get report_path("2026-10") }
    absence = Absence.create!(teacher: users(:guru_mapel), date: Date.new(2026, 10, 12), reason: "lainnya", created_by: users(:wakil_kurikulum))
    Activation.create!(absence: absence, lesson: lessons(:senin_jam1_7a), invigilator: users(:guru_piket), activated_at: Time.current, completed_at: Time.current + 1.hour)
    assert_equal before, count_queries { get report_path("2026-10") }
  end
end
