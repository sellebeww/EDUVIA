# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class Activations::PlanTest < ActiveSupport::TestCase
  MONDAY = Date.new(2026, 11, 9)

  test "satu item per jam mengajar, berurutan menurut jam" do
    plan = Activations::Plan.new(teacher: users(:guru_mapel), date: MONDAY)
    assert_equal [ lessons(:senin_jam1_7a), lessons(:senin_jam2_8a) ], plan.items.map(&:lesson)
  end

  test "kit cocok dan peringatan untuk kelas tanpa kit serta tanpa piket" do
    items = Activations::Plan.new(teacher: users(:guru_mapel), date: MONDAY).items
    assert_equal kits(:mtk_7a_siap), items[0].kit
    assert_equal %w[no_invigilator], items[0].warning_codes
    assert_nil items[1].kit
    assert_equal %w[no_kit no_invigilator], items[1].warning_codes
  end

  test "dengan guru piket bertugas tidak ada peringatan piket" do
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY)
    items = Activations::Plan.new(teacher: users(:guru_mapel), date: MONDAY).items
    assert_equal users(:guru_piket), items[0].invigilator
    assert_equal %w[no_kit], items[1].warning_codes
  end

  test "tidak menulis apa pun ke database" do
    assert_no_difference [ "Absence.count", "Activation.count", "AttendanceRecord.count" ] do
      Activations::Plan.new(teacher: users(:guru_mapel), date: MONDAY).items
    end
    assert kits(:mtk_7a_siap).reload.disiapkan?
  end

  test "guru tanpa jam mengajar pada hari itu: rencana kosong" do
    assert Activations::Plan.new(teacher: users(:guru_mapel), date: MONDAY + 2).empty?
  end

  test "item yang sudah diaktifkan ditandai existing" do
    absence = Absence.create!(teacher: users(:guru_mapel), date: MONDAY, reason: "sakit", created_by: users(:wakil_kurikulum))
    Activation.create!(absence: absence, lesson: lessons(:senin_jam1_7a), activated_at: Time.current, warning_codes: %w[no_kit])
    items = Activations::Plan.new(teacher: users(:guru_mapel), date: MONDAY).items
    assert items[0].existing?
    assert_not items[1].existing?
  end
end
