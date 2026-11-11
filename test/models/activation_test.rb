# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class ActivationTest < ActiveSupport::TestCase
  MONDAY = Date.new(2026, 11, 9)

  setup do
    @absence = Absence.create!(teacher: users(:guru_mapel), date: MONDAY, reason: "sakit", created_by: users(:wakil_kurikulum))
    @lesson = lessons(:senin_jam1_7a)
  end

  def build(attrs = {})
    Activation.new({ absence: @absence, lesson: @lesson, kit: kits(:mtk_7a_siap), invigilator: users(:guru_piket), activated_at: Time.current }.merge(attrs))
  end

  test "valid dengan kit dan guru piket" do
    assert build.valid?, build.errors.full_messages.to_s
  end

  test "kit dan guru piket boleh kosong (mode cadangan, menunggu piket)" do
    activation = build(kit: nil, invigilator: nil, warning_codes: %w[no_kit no_invigilator])
    assert activation.valid?
    assert_equal :menunggu_piket, activation.status
    assert_equal 2, activation.warnings.size
  end

  test "status turunan" do
    assert_equal :aktif, build.status
    assert_equal :selesai, build(completed_at: Time.current + 1.minute).status
  end

  test "jam pelajaran hanya sekali per ketidakhadiran" do
    build.save!
    dup = build(kit: nil)
    assert_not dup.valid?
    assert_raises(ActiveRecord::RecordNotUnique) { dup.save!(validate: false) }
  end

  test "satu kit tidak bisa terbuka di dua aktivasi sekaligus (database)" do
    build.save!
    other_absence = Absence.create!(teacher: users(:guru_mapel), date: MONDAY + 1, reason: "izin", created_by: users(:wakil_kurikulum))
    other = build(absence: other_absence)
    assert_raises(ActiveRecord::RecordNotUnique) { other.save!(validate: false) }
  end

  test "kit boleh dipakai lagi setelah aktivasi sebelumnya selesai" do
    build(completed_at: Time.current + 1.minute).save!
    other_absence = Absence.create!(teacher: users(:guru_mapel), date: MONDAY + 1, reason: "izin", created_by: users(:wakil_kurikulum))
    assert_nothing_raised { build(absence: other_absence).save!(validate: false) }
  end

  test "jam pelajaran harus milik guru yang berhalangan" do
    assert_not build(lesson: lessons(:senin_jam2_7a)).valid? # diajar guru_mapel_dua
  end

  test "kit harus cocok dengan mapel dan kelas jam pelajaran" do
    assert_not build(kit: kits(:ipa_7a_siap)).valid?
  end

  test "invigilator harus guru_piket" do
    assert_not build(invigilator: users(:guru_mapel)).valid?
  end

  test "kode peringatan harus dikenal" do
    assert_not build(warning_codes: %w[ngawur]).valid?
  end

  test "selesai tidak boleh sebelum aktif" do
    assert_not build(completed_at: 1.day.ago).valid?
  end

  test "scope open, completed, within" do
    a = build.tap(&:save!)
    assert_includes Activation.open, a
    assert_not_includes Activation.completed, a
    assert_includes Activation.within(1.hour.ago..1.hour.from_now), a
  end
end
