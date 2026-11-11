# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class IconsHelperTest < ActionView::TestCase
  test "ikon berupa svg dekoratif yang disembunyikan dari pembaca layar" do
    html = icon("check", size: 18)
    assert_includes html, "<svg"
    assert_includes html, 'aria-hidden="true"'
    assert_includes html, 'width="18"'
    assert_includes html, 'class="icon"'
  end

  test "semua ikon terdaftar menghasilkan svg dengan isi" do
    IconsHelper::ICONS.each_key do |name|
      assert_match(%r{<svg.*<(path|circle|rect)}m, icon(name), name)
    end
  end

  test "ikon yang tidak dikenal gagal keras, bukan diam-diam kosong" do
    assert_raises(KeyError) { icon("tidak-ada") }
  end

  test "inisial avatar: dua kata pertama, gelar diabaikan" do
    assert_equal "SW", initials("Sari Wulandari")
    assert_equal "BH", initials("Drs. Bambang Hartono")
    assert_equal "R", initials("Rina")
    assert_equal "", initials(nil)
  end
end
