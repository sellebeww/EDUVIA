# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class LessonTest < ActiveSupport::TestCase
  def build(attrs = {})
    Lesson.new({ school_class: school_classes(:kelas_8a), subject: subjects(:ipa), teacher: users(:guru_mapel_dua),
                 period: periods(:jam_2), day_of_week: 3 }.merge(attrs))
  end

  test "valid" do
    assert build.valid?, build.errors.full_messages.to_s
  end

  test "kelas tidak bisa dobel jam pada slot yang sama" do
    lesson = build(school_class: school_classes(:kelas_7a), period: periods(:jam_1), day_of_week: 1)
    assert_not lesson.valid?
    assert lesson.errors[:period_id].any?
  end

  test "guru tidak bisa mengajar dua kelas bersamaan" do
    lesson = build(teacher: users(:guru_mapel), period: periods(:jam_1), day_of_week: 1, school_class: school_classes(:kelas_8a))
    assert_not lesson.valid?
    assert_includes lesson.errors[:period_id].join, "guru ini"
  end

  test "batas unik juga dijaga database" do
    dup = build(school_class: school_classes(:kelas_7a), period: periods(:jam_1), day_of_week: 1)
    assert_raises(ActiveRecord::RecordNotUnique) { dup.save!(validate: false) }
  end

  test "tanpa kelas, guru, mapel, atau jam: tidak valid dan tidak meledak" do
    lesson = Lesson.new(day_of_week: 1)
    assert_nothing_raised { lesson.valid? }
    assert_not lesson.valid?
    assert lesson.errors[:school_class].any?
  end

  test "hari harus 1..7 dan termasuk hari aktif sekolah" do
    assert_not build(day_of_week: 0).valid?
    assert_not build(day_of_week: 8).valid?
    saturday = build(day_of_week: 6)
    assert_not saturday.valid?
    assert saturday.errors[:day_of_week].any?
  end

  test "hari aktif mengikuti konfigurasi sekolah, bukan hard-code" do
    schools(:smp).update!(active_days: [ 1, 2, 3, 4, 5, 6 ])
    assert build(day_of_week: 6).valid?
  end

  test "jam istirahat tidak bisa dijadwalkan" do
    assert_not build(period: periods(:istirahat)).valid?
  end

  test "guru harus berperan guru_mapel" do
    assert_not build(teacher: users(:guru_piket)).valid?
  end

  test "mapel, jam, dan guru harus dari sekolah yang sama" do
    assert_not build(subject: subjects(:mapel_lain)).valid?
    assert_not build(period: periods(:jam_lain)).valid?
    assert_not build(teacher: users(:guru_lain)).valid?
  end

  test "scope on_weekday, by_teacher, chronological" do
    monday = Date.new(2026, 11, 9)
    assert_equal 1, monday.cwday
    assert_equal 3, Lesson.on_weekday(monday).count
    assert_equal 2, Lesson.on_weekday(monday).by_teacher(users(:guru_mapel)).count
    assert_equal [ 1, 2, 2 ], Lesson.on_weekday(monday).chronological.map { |l| l.period.number }
  end
end
