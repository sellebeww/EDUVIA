# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class SubmissionTest < ActiveSupport::TestCase
  setup do
    absence = Absence.create!(teacher: users(:guru_mapel), date: Date.new(2026, 11, 9), reason: "sakit", created_by: users(:wakil_kurikulum))
    @activation = Activation.create!(absence: absence, lesson: lessons(:senin_jam1_7a), kit: kits(:mtk_7a_siap), invigilator: users(:guru_piket), activated_at: Time.current)
  end

  def build(attrs = {})
    Submission.new({ activation: @activation, student: students(:andi) }.merge(attrs))
  end

  test "bawaan belum mengumpulkan" do
    assert_not build.submitted?
  end

  test "nilai 0..100 atau kosong" do
    assert build(score: nil).valid?
    assert build(score: 0).valid?
    assert build(score: 100).valid?
    assert_not build(score: 101).valid?
    assert_not build(score: -1).valid?
    assert_not build(score: 7.5).valid?
  end

  test "waktu kumpul terisi saat submitted dan hilang saat dibatalkan" do
    submission = build(submitted: true)
    submission.save!
    assert submission.submitted_at.present?
    first = submission.submitted_at
    submission.update!(score: 80)
    assert_equal first, submission.reload.submitted_at
    submission.update!(submitted: false)
    assert_nil submission.reload.submitted_at
  end

  test "siswa harus dari kelas jam pelajaran dan unik per aktivasi" do
    assert_not build(student: students(:dimas)).valid?
    build.save!
    assert_not build.valid?
  end
end
