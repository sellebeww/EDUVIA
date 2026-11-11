# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class AbsenceTest < ActiveSupport::TestCase
  MONDAY = Date.new(2026, 11, 9)

  def build(attrs = {})
    Absence.new({ teacher: users(:guru_mapel), date: MONDAY, reason: "sakit", created_by: users(:wakil_kurikulum) }.merge(attrs))
  end

  test "valid" do
    assert build.valid?, build.errors.full_messages.to_s
    assert_equal "Sakit", build.reason_label
  end

  test "alasan harus salah satu dari daftar" do
    assert_not build(reason: "malas").valid?
    assert_not build(reason: nil).valid?
  end

  test "guru harus guru_mapel dan pembuat harus wakil_kurikulum" do
    assert_not build(teacher: users(:guru_piket)).valid?
    assert_not build(created_by: users(:guru_mapel)).valid?
  end

  test "satu guru hanya sekali berhalangan per tanggal" do
    build.save!
    dup = build
    assert_not dup.valid?
    assert_raises(ActiveRecord::RecordNotUnique) { dup.save!(validate: false) }
  end

  test "tanggal harus hari aktif sekolah" do
    assert_not build(date: Date.new(2026, 11, 14)).valid?, "Sabtu bukan hari aktif"
    assert_not build(date: Date.new(2026, 11, 15)).valid?, "Minggu bukan hari aktif"
  end

  test "catatan dibatasi 200 karakter" do
    assert_not build(note: "x" * 201).valid?
  end
end
