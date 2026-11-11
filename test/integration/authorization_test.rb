# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

# Matriks peran x halaman: tiap peran hanya boleh membuka halamannya sendiri.
class AuthorizationTest < ActionDispatch::IntegrationTest
  ACCESS = {
    "/kits" => %i[guru_mapel],
    "/duty" => %i[guru_piket],
    "/curriculum" => %i[wakil_kurikulum],
    "/curriculum/school" => %i[wakil_kurikulum],
    "/curriculum/periods" => %i[wakil_kurikulum],
    "/curriculum/school_classes" => %i[wakil_kurikulum],
    "/curriculum/subjects" => %i[wakil_kurikulum],
    "/curriculum/lessons" => %i[wakil_kurikulum],
    "/curriculum/duty_assignments" => %i[wakil_kurikulum],
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

  test "peran lain tidak bisa membuat, mengubah, atau mengunduh kit" do
    kit = kits(:mtk_7a_siap)
    %i[guru_piket wakil_kurikulum kepala_sekolah].each do |role|
      log_in_as role
      assert_no_difference "Kit.count" do
        post kits_path, params: { kit: { title: "X", supervisor_instructions: "Y", assignment: "1:1" } }
      end
      assert_response :forbidden, role
      get worksheet_kit_path(kit)
      assert_response :forbidden, role
      delete kit_path(kit)
      assert_response :forbidden, role
      delete session_path
    end
    assert Kit.exists?(kit.id)
  end

  test "peran lain tidak bisa menulis data master (POST/PATCH/DELETE ditolak)" do
    log_in_as :guru_mapel
    assert_no_difference "Subject.count" do
      post curriculum_subjects_path, params: { subject: { name: "Seni", code: "SBK" } }
    end
    assert_response :forbidden
    delete curriculum_subject_path(subjects(:matematika))
    assert_response :forbidden
    assert Subject.exists?(subjects(:matematika).id)
  end
end
