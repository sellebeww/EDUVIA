# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class DutyAssignmentTest < ActiveSupport::TestCase
  test "hanya guru piket yang bisa ditugaskan" do
    assert DutyAssignment.new(user: users(:guru_piket), date: Date.new(2026, 11, 9)).valid?
    assert_not DutyAssignment.new(user: users(:guru_mapel), date: Date.new(2026, 11, 9)).valid?
  end

  test "satu guru piket hanya sekali per tanggal" do
    DutyAssignment.create!(user: users(:guru_piket), date: Date.new(2026, 11, 9))
    dup = DutyAssignment.new(user: users(:guru_piket), date: Date.new(2026, 11, 9))
    assert_not dup.valid?
    assert DutyAssignment.new(user: users(:guru_piket_dua), date: Date.new(2026, 11, 9)).valid?
    assert_raises(ActiveRecord::RecordNotUnique) { dup.save!(validate: false) }
  end

  test "tanggal wajib" do
    assert_not DutyAssignment.new(user: users(:guru_piket), date: nil).valid?
  end

  test "scope on dan between" do
    d = Date.new(2026, 11, 9)
    DutyAssignment.create!(user: users(:guru_piket), date: d)
    DutyAssignment.create!(user: users(:guru_piket), date: d + 2)
    assert_equal 1, DutyAssignment.on(d).count
    assert_equal 2, DutyAssignment.between(d, d + 3).count
  end
end
