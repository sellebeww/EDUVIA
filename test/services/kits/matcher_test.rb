# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class Kits::MatcherTest < ActiveSupport::TestCase
  setup do
    @teacher = users(:guru_mapel)
    @lesson = lessons(:senin_jam1_7a) # 7A Matematika
  end

  test "memilih kit disiapkan lebih dulu dari kit terpakai" do
    match = Kits::Matcher.new(@teacher).match(@lesson)
    assert_equal kits(:mtk_7a_siap), match.kit
    assert_not match.reused
  end

  test "bila hanya ada kit terpakai, dipakai ulang dan ditandai" do
    kits(:mtk_7a_siap).destroy
    match = Kits::Matcher.new(@teacher).match(@lesson)
    assert_equal kits(:mtk_7a_terpakai), match.kit
    assert match.reused
  end

  test "tanpa kit untuk kelas dan mapel itu hasilnya kosong, bukan galat" do
    match = Kits::Matcher.new(@teacher).match(lessons(:senin_jam2_8a)) # 8A Matematika: tidak ada kit
    assert_nil match.kit
    assert_not match.reused
  end

  test "kit aktif dilewati" do
    kits(:mtk_7a_siap).activate!
    match = Kits::Matcher.new(@teacher).match(@lesson)
    assert_equal kits(:mtk_7a_terpakai), match.kit
  end

  test "kit yang sama tidak dipilih dua kali pada satu pemanggilan (jam ganda)" do
    double = Lesson.create!(school_class: school_classes(:kelas_7a), subject: subjects(:matematika), teacher: @teacher, period: periods(:jam_1), day_of_week: 2)
    matcher = Kits::Matcher.new(@teacher)
    first = matcher.match(@lesson)
    second = matcher.match(double)
    third = matcher.match(double)
    assert_equal kits(:mtk_7a_siap), first.kit
    assert_equal kits(:mtk_7a_terpakai), second.kit
    assert second.reused
    assert_nil third.kit
  end

  test "kit guru lain tidak pernah dipilih" do
    match = Kits::Matcher.new(users(:guru_mapel)).match(lessons(:senin_jam2_7a)) # IPA 7A milik guru_mapel_dua
    assert_nil match.kit
  end

  test "di antara kit terpakai, yang paling lama tidak dipakai dipilih lebih dulu" do
    kits(:mtk_7a_siap).destroy
    older = Kit.create!(kits(:mtk_7a_terpakai).attributes.slice("user_id", "subject_id", "school_class_id", "duration_minutes", "supervisor_instructions").merge(title: "Lama", status: "terpakai", last_used_at: 30.days.ago))
    assert_equal older, Kits::Matcher.new(@teacher).match(@lesson).kit
  end

  test "hanya satu query untuk semua jam" do
    matcher = nil
    assert_queries_count(1) { matcher = Kits::Matcher.new(@teacher) }
    assert_no_queries { matcher.match(@lesson) }
  end
end
