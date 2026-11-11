# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class StudentTest < ActiveSupport::TestCase
  test "nomor absen unik per kelas" do
    assert_not Student.new(school_class: school_classes(:kelas_7a), name: "Baru", roll_number: 1).valid?
    assert Student.new(school_class: school_classes(:kelas_8a), name: "Baru", roll_number: 2).valid?
  end

  test "nama dan nomor absen wajib" do
    assert_not Student.new(school_class: school_classes(:kelas_7a), name: "", roll_number: 9).valid?
    assert_not Student.new(school_class: school_classes(:kelas_7a), name: "X", roll_number: 0).valid?
  end

  test "ordered mengurutkan menurut nomor absen" do
    assert_equal %w[Andi\ Saputra Bella\ Anggraini Citra\ Dewi], school_classes(:kelas_7a).students.ordered.pluck(:name)
  end
end
