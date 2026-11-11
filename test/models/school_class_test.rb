# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class SchoolClassTest < ActiveSupport::TestCase
  test "fase diturunkan dari tingkat kelas" do
    { 1 => "A", 2 => "A", 3 => "B", 4 => "B", 5 => "C", 6 => "C", 7 => "D", 8 => "D", 9 => "D", 10 => "E", 11 => "F", 12 => "F" }.each do |grade, phase|
      assert_equal phase, SchoolClass.new(grade_level: grade).phase, "kelas #{grade}"
    end
  end

  test "nama wajib dan unik per sekolah, boleh sama di sekolah lain" do
    assert_not SchoolClass.new(school: schools(:smp), name: "", grade_level: 7).valid?
    assert_not SchoolClass.new(school: schools(:smp), name: "VII A", grade_level: 7).valid?
    assert SchoolClass.new(school: schools(:smp), name: "VII B", grade_level: 7).valid?
  end

  test "tingkat kelas harus 1..12" do
    [ 0, 13, nil ].each { |g| assert_not SchoolClass.new(school: schools(:smp), name: "X", grade_level: g).valid?, g.inspect }
  end

  test "kelas yang punya jadwal tidak bisa dihapus, siswa ikut terhapus bila kelas kosong" do
    assert_not school_classes(:kelas_7a).destroy
    empty = SchoolClass.create!(school: schools(:smp), name: "IX Z", grade_level: 9)
    empty.students.create!(name: "X", roll_number: 1)
    assert_difference "Student.count", -1 do
      assert empty.destroy
    end
  end
end
