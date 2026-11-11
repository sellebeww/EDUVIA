# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  HOMES = {
    guru_mapel: [ "/kits", "Bank Kit Saya" ],
    guru_piket: [ "/duty", "Kit Hari Ini" ],
    wakil_kurikulum: [ "/curriculum", "Jam Kosong Hari Ini" ],
    kepala_sekolah: [ "/reports", "Laporan Bulanan" ]
  }.freeze

  HOMES.each do |role, (path, heading)|
    test "login #{role} mendarat di beranda perannya" do
      log_in_as role
      assert_redirected_to root_url
      follow_redirect!
      assert_redirected_to path
      follow_redirect!
      assert_response :success
      assert_select "h1", heading
      assert_select ".user-menu .badge", users(role).role_label
    end
  end

  test "halaman masuk tampil tanpa login" do
    get new_session_path
    assert_response :success
    assert_select "form[action='#{session_path}']"
    assert_select "label", "Email"
  end

  test "kata sandi salah ditolak dengan pesan berbahasa Indonesia" do
    post session_path, params: { email_address: users(:guru_mapel).email_address, password: "salah" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select ".alert--danger", "Email atau kata sandi salah."
  end

  test "email tidak terdaftar ditolak" do
    post session_path, params: { email_address: "tidak.ada@example.test", password: "password" }
    assert_redirected_to new_session_path
  end

  test "keluar mengakhiri sesi" do
    log_in_as :guru_mapel
    delete session_path
    assert_redirected_to new_session_path
    get kits_path
    assert_redirected_to new_session_path
  end

  test "tanpa login semua halaman aplikasi diarahkan ke halaman masuk" do
    [ root_path, kits_path, duty_root_path, curriculum_root_path, reports_path ].each do |path|
      get path
      assert_redirected_to new_session_path, "#{path} seharusnya butuh login"
    end
  end

  test "setelah login kembali ke halaman yang diminta semula" do
    get reports_path
    log_in_as :kepala_sekolah
    assert_redirected_to reports_url
  end
end
