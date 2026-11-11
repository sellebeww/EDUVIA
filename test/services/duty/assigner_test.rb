# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class Duty::AssignerTest < ActiveSupport::TestCase
  MONDAY = Date.new(2026, 11, 9)

  def duty(*users) = users.each { |u| DutyAssignment.create!(user: u, date: MONDAY) }
  def assigner = Duty::Assigner.new(date: MONDAY, school: schools(:smp))

  test "tanpa guru piket: kosong dengan peringatan no_invigilator" do
    pick = assigner.assign(periods(:jam_1).id)
    assert_nil pick.user
    assert_equal %w[no_invigilator], pick.warning_codes
  end

  test "satu guru piket menerima, tanpa peringatan" do
    duty users(:guru_piket)
    pick = assigner.assign(periods(:jam_1).id)
    assert_equal users(:guru_piket), pick.user
    assert_empty pick.warning_codes
  end

  test "dua kelas kosong bersamaan dibagi ke dua guru piket" do
    duty users(:guru_piket), users(:guru_piket_dua)
    a = assigner
    first = a.assign(periods(:jam_1).id)
    second = a.assign(periods(:jam_1).id)
    assert_not_equal first.user, second.user
    assert_empty first.warning_codes + second.warning_codes
  end

  test "guru piket tunggal menangani dua kelas bersamaan dengan peringatan bentrok" do
    duty users(:guru_piket)
    a = assigner
    a.assign(periods(:jam_1).id)
    second = a.assign(periods(:jam_1).id)
    assert_equal users(:guru_piket), second.user
    assert_equal %w[concurrent_conflict], second.warning_codes
  end

  test "bila semua sibuk pada jam itu, tetap ditugaskan ke yang bebannya paling sedikit" do
    duty users(:guru_piket), users(:guru_piket_dua)
    a = assigner
    a.assign(periods(:jam_1).id)
    a.assign(periods(:jam_1).id)
    third = a.assign(periods(:jam_1).id)
    assert_equal %w[concurrent_conflict], third.warning_codes
    assert third.user
  end

  test "beban dibagi rata pada jam yang berbeda" do
    duty users(:guru_piket), users(:guru_piket_dua)
    a = assigner
    picks = [ periods(:jam_1), periods(:jam_2), periods(:jam_1), periods(:jam_2) ].map { |p| a.assign(p.id).user }
    assert_equal 2, picks.count(users(:guru_piket))
    assert_equal 2, picks.count(users(:guru_piket_dua))
  end

  test "memperhitungkan aktivasi terbuka yang sudah ada di database" do
    duty users(:guru_piket), users(:guru_piket_dua)
    absence = Absence.create!(teacher: users(:guru_mapel), date: MONDAY, reason: "sakit", created_by: users(:wakil_kurikulum))
    Activation.create!(absence: absence, lesson: lessons(:senin_jam1_7a), invigilator: users(:guru_piket_dua), activated_at: Time.current)
    pick = assigner.assign(periods(:jam_1).id) # guru_piket_dua sibuk di jam 1
    assert_equal users(:guru_piket), pick.user
    assert_empty pick.warning_codes
  end

  test "guru piket dari sekolah lain tidak dipilih" do
    outsider = User.create!(school: schools(:lain), name: "Piket Lain", email_address: "piket.lain@example.test", password: "rahasia123", role: "guru_piket")
    duty outsider
    assert_nil assigner.assign(periods(:jam_1).id).user
  end

  test "penugasan di tanggal lain tidak dihitung" do
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY + 1)
    assert_nil assigner.assign(periods(:jam_1).id).user
  end
end
