# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class KitTemplateTest < ActiveSupport::TestCase
  test "ada tiga templat dengan kunci unik" do
    assert_equal 3, KitTemplate.all.size
    assert_equal KitTemplate.all.size, KitTemplate.all.map(&:key).uniq.size
  end

  test "find berdasarkan kunci, nil bila tidak ada" do
    assert_equal "Latihan Soal Mandiri", KitTemplate.find("latihan_soal").title
    assert_nil KitTemplate.find("tidak-ada")
    assert_nil KitTemplate.find(nil)
  end

  test "atribut templat memenuhi validasi kit (durasi, petunjuk terisi menit)" do
    KitTemplate.all.each do |t|
      attrs = t.attributes
      assert_includes 30..40, attrs[:duration_minutes], t.key
      assert_includes attrs[:supervisor_instructions], "#{attrs[:duration_minutes]} menit", t.key
      assert_not_includes attrs[:supervisor_instructions], "%", t.key
      kit = Kit.new(attrs.merge(user: users(:guru_mapel), subject: subjects(:matematika), school_class: school_classes(:kelas_7a)))
      assert kit.valid?, "#{t.key}: #{kit.errors.full_messages}"
    end
  end
end
