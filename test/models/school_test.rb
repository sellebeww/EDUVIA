# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class SchoolTest < ActiveSupport::TestCase
  test "fixture valid" do
    assert schools(:smp).valid?
  end

  test "nama wajib" do
    school = School.new(name: "")
    assert_not school.valid?
    assert school.errors.added?(:name, :blank)
  end

  test "hari aktif default Senin sampai Jumat" do
    assert_equal [ 1, 2, 3, 4, 5 ], School.new.active_days
  end

  test "hari aktif tidak boleh kosong, di luar 1..7, atau berulang" do
    [ [], [ 0 ], [ 8 ], [ 1, 1 ] ].each do |days|
      school = School.new(name: "X", active_days: days)
      assert_not school.valid?, "#{days.inspect} seharusnya tidak valid"
      assert school.errors[:active_days].any?
    end
  end

  test "sekolah dengan pengguna tidak bisa dihapus" do
    assert_not schools(:smp).destroy
    assert School.exists?(schools(:smp).id)
  end

  test "tidak boleh menghapus hari aktif yang masih punya jadwal" do
    school = schools(:smp)
    assert_not school.update(active_days: [ 2, 3, 4, 5 ]) # Senin masih punya pelajaran
    assert school.errors[:active_days].any?
  end

  test "boleh menambah hari aktif atau menghapus hari tanpa jadwal" do
    school = schools(:smp)
    assert school.update(active_days: [ 1, 2, 3, 4, 5, 6 ])
    assert school.update(active_days: [ 1, 2 ])
  end
end
