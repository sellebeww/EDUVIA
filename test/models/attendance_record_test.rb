# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class AttendanceRecordTest < ActiveSupport::TestCase
  setup do
    absence = Absence.create!(teacher: users(:guru_mapel), date: Date.new(2026, 11, 9), reason: "sakit", created_by: users(:wakil_kurikulum))
    @activation = Activation.create!(absence: absence, lesson: lessons(:senin_jam1_7a), kit: kits(:mtk_7a_siap), invigilator: users(:guru_piket), activated_at: Time.current)
  end

  test "bawaan hadir, status hanya hadir atau tidak_hadir" do
    record = AttendanceRecord.new(activation: @activation, student: students(:andi))
    assert record.hadir?
    assert record.valid?
    record.status = "izin"
    assert_not record.valid?
  end

  test "satu baris per siswa per aktivasi" do
    AttendanceRecord.create!(activation: @activation, student: students(:andi))
    assert_not AttendanceRecord.new(activation: @activation, student: students(:andi)).valid?
  end

  test "siswa harus dari kelas jam pelajaran" do
    assert_not AttendanceRecord.new(activation: @activation, student: students(:dimas)).valid?
  end
end
