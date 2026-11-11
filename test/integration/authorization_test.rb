# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

# Matriks peran x halaman: tiap peran hanya boleh membuka halamannya sendiri.
class AuthorizationTest < ActionDispatch::IntegrationTest
  ACCESS = {
    "/kits" => %i[guru_mapel],
    "/duty" => %i[guru_piket],
    "/curriculum" => %i[wakil_kurikulum],
    "/reports" => %i[wakil_kurikulum kepala_sekolah]
  }.freeze

  ACCESS.each do |path, allowed|
    User::ROLES.map(&:to_sym).each do |role|
      expected = allowed.include?(role) ? :success : :forbidden
      test "#{role} membuka #{path} => #{expected}" do
        log_in_as role
        get path
        assert_response expected
      end
    end
  end

  test "halaman 403 memberi jalan pulang ke beranda peran" do
    log_in_as :guru_piket
    get kits_path
    assert_response :forbidden
    assert_select "h1", "Akses ditolak"
    assert_select "a[href='/duty']", "Kembali ke beranda"
  end

  test "menu navigasi hanya memuat halaman yang boleh diakses" do
    log_in_as :kepala_sekolah
    get reports_path
    assert_select ".main-nav a", count: 1
    assert_select ".main-nav a[href='/reports']"
  end
end
