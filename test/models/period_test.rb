# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class PeriodTest < ActiveSupport::TestCase
  def build(attrs = {})
    Period.new({ school: schools(:smp), number: 9, starts_at: "10:00", ends_at: "10:40" }.merge(attrs))
  end

  test "valid" do
    assert build.valid?
  end

  test "nomor wajib, bulat, positif, dan unik per sekolah" do
    assert_not build(number: nil).valid?
    assert_not build(number: 0).valid?
    assert_not build(number: 1).valid?, "nomor 1 sudah dipakai di sekolah yang sama"
    assert build(school: schools(:lain), number: 2).valid?
  end

  test "selesai harus setelah mulai" do
    period = build(starts_at: "10:00", ends_at: "09:00")
    assert_not period.valid?
    assert period.errors[:ends_at].any?
  end

  test "scope teaching mengecualikan istirahat dan ordered mengurutkan" do
    ids = schools(:smp).periods.teaching.ordered.pluck(:id)
    assert_equal [ periods(:jam_1).id, periods(:jam_2).id ], ids
  end

  test "nama dan rentang waktu" do
    assert_equal "Jam ke-1", periods(:jam_1).display_name
    assert_equal "Istirahat", periods(:istirahat).display_name
    assert_equal "07.00–07.40", periods(:jam_1).time_range
  end

  test "jam yang dipakai jadwal tidak bisa dihapus" do
    assert_not periods(:jam_1).destroy
  end
end
