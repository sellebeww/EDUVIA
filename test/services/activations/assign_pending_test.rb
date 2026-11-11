# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class Activations::AssignPendingTest < ActiveSupport::TestCase
  MONDAY = Date.new(2026, 11, 9)

  setup do
    Activations::Create.call(actor: users(:wakil_kurikulum), teacher: users(:guru_mapel), date: MONDAY, reason: "sakit", today: MONDAY)
  end

  test "aktivasi yang menunggu langsung diberikan saat guru piket ditugaskan, lalu kartunya disiarkan" do
    assert Activation.all.all? { |a| a.invigilator.nil? }
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY)
    assigned = nil
    assert_turbo_stream_broadcasts("duty_#{users(:guru_piket).id}", count: 1) do
      assigned = Activations::AssignPending.call(date: MONDAY, school: schools(:smp))
    end
    assert_equal 2, assigned.size
    Activation.all.each do |a|
      assert_equal users(:guru_piket), a.reload.invigilator
      assert_not_includes a.warning_codes, "no_invigilator"
    end
  end

  test "peringatan no_kit dipertahankan" do
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY)
    Activations::AssignPending.call(date: MONDAY, school: schools(:smp))
    assert_includes Activation.find_by(lesson: lessons(:senin_jam2_8a)).warning_codes, "no_kit"
  end

  test "tanpa guru piket tidak ada yang berubah" do
    assert_empty Activations::AssignPending.call(date: MONDAY, school: schools(:smp))
  end

  test "tanggal lain tidak terpengaruh" do
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY + 1)
    assert_empty Activations::AssignPending.call(date: MONDAY + 1, school: schools(:smp))
    assert Activation.all.all? { |a| a.invigilator.nil? }
  end

  test "aktivasi yang sudah selesai tidak disentuh" do
    Activation.update_all(completed_at: Time.current + 1.minute)
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY)
    assert_empty Activations::AssignPending.call(date: MONDAY, school: schools(:smp))
  end
end
