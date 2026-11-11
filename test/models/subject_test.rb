# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class SubjectTest < ActiveSupport::TestCase
  test "kode dinormalisasi huruf besar dan unik per sekolah" do
    subject = Subject.new(school: schools(:smp), name: "Seni", code: " sbk ")
    assert subject.valid?
    assert_equal "SBK", subject.code
    assert_not Subject.new(school: schools(:smp), name: "Lain", code: "mtk").valid?
    assert Subject.new(school: schools(:lain), name: "Seni", code: "SBK").valid?
  end

  test "nama dan kode wajib" do
    assert_not Subject.new(school: schools(:smp), name: "", code: "X").valid?
    assert_not Subject.new(school: schools(:smp), name: "X", code: "").valid?
  end

  test "mapel yang dipakai jadwal tidak bisa dihapus" do
    assert_not subjects(:matematika).destroy
  end
end
