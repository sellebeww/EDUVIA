# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class SecurityTest < ActionDispatch::IntegrationTest
  PUBLIC_ACTIONS = %w[sessions#new sessions#create passwords#new passwords#create passwords#edit passwords#update].freeze
  OK_STATUSES = [ 200, 302, 303, 400, 403, 404, 409, 422 ].freeze

  # Semua rute aplikasi sendiri (controller turunan ApplicationController) beserta verbnya.
  def app_routes
    Rails.application.routes.routes.filter_map do |route|
      controller, action = route.defaults.values_at(:controller, :action)
      klass = controller && "#{controller.camelize}Controller".safe_constantize
      verb = route.verb.to_s[/[A-Z]+/]
      next unless klass && klass < ApplicationController && verb && verb != "HEAD"

      path = route.path.spec.to_s.sub("(.:format)", "").gsub(/:\w+/, "1")
      { key: "#{controller}##{action}", verb: verb.downcase, path: path }
    end
  end

  test "penyapu rute: ada cukup banyak rute yang diperiksa" do
    assert_operator app_routes.size, :>=, 40
  end

  test "tanpa login semua rute non-publik mengarah ke halaman masuk (tidak ada yang lolos)" do
    app_routes.reject { |r| PUBLIC_ACTIONS.include?(r[:key]) }.each do |r|
      public_send(r[:verb], r[:path])
      assert_redirected_to new_session_path, "#{r[:verb].upcase} #{r[:path]} (#{r[:key]}) harus butuh login"
    end
  end

  test "untuk setiap peran tidak ada rute yang menghasilkan galat server (5xx) walau ID dan parameter ngawur" do
    User::ROLES.each do |role|
      log_in_as role.to_sym
      app_routes.reject { |r| r[:key].start_with?("sessions#") || r[:key].start_with?("passwords#") }.each do |r|
        public_send(r[:verb], r[:path])
        assert_includes OK_STATUSES, response.status, "#{role}: #{r[:verb].upcase} #{r[:path]} (#{r[:key]}) => #{response.status}"
      end
      delete session_path
    end
  end

  test "rute publik Active Storage tidak ada (unduhan hanya lewat aksi dengan pengecekan hak akses)" do
    get "/rails/active_storage/blobs/redirect/abc123/lembar-kerja.pdf"
    assert_response :not_found
    get "/rails/active_storage/disk/abc123/lembar-kerja.pdf"
    assert_response :not_found
  end

  test "Content-Security-Policy: hanya sumber sendiri, skrip dengan nonce, tanpa framing" do
    get new_session_path
    csp = response.headers["Content-Security-Policy"]
    assert csp, "header CSP harus ada"
    assert_includes csp, "default-src 'self'"
    assert_includes csp, "object-src 'none'"
    assert_includes csp, "frame-ancestors 'none'"
    assert_includes csp, "base-uri 'self'"
    assert_includes csp, "form-action 'self'"
    assert_match(/script-src 'self' 'nonce-[\w+\/=]+'/, csp)
    assert_not_includes csp, "unsafe-eval"
    nonce = csp[/nonce-([\w+\/=]+)/, 1]
    assert_select "script[type=importmap][nonce='#{nonce}']"
  end

  test "nonce CSP berbeda di tiap permintaan" do
    get new_session_path
    first = response.headers["Content-Security-Policy"][/nonce-([\w+\/=]+)/, 1]
    get new_session_path
    assert_not_equal first, response.headers["Content-Security-Policy"][/nonce-([\w+\/=]+)/, 1]
  end

  test "header keamanan dasar terpasang" do
    log_in_as :guru_mapel
    get kits_path
    assert_equal "SAMEORIGIN", response.headers["X-Frame-Options"]
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
  end

  test "CSRF: permintaan tulis tanpa token ditolak, dengan token diterima" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    post session_path, params: { email_address: users(:guru_mapel).email_address, password: "password" }
    assert_response :unprocessable_entity

    get new_session_path
    token = css_select("meta[name=csrf-token]").first["content"]
    post session_path, params: { authenticity_token: token, email_address: users(:guru_mapel).email_address, password: "password" }
    assert_response :redirect
    assert_not_equal new_session_url, response.location
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  test "cookie sesi: httponly dan SameSite=Lax" do
    post session_path, params: { email_address: users(:guru_mapel).email_address, password: "password" }
    cookie = response.headers["Set-Cookie"].to_s
    assert_match(/session_id=/, cookie)
    assert_match(/httponly/i, cookie)
    assert_match(/samesite=lax/i, cookie)
  end

  test "batas percobaan per akun: percobaan ke-11 diblokir dengan pesan Indonesia, walau kata sandi benar" do
    10.times { post session_path, params: { email_address: users(:guru_mapel).email_address, password: "salah" } }
    post session_path, params: { email_address: users(:guru_mapel).email_address, password: "password" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select ".alert--danger", /Terlalu banyak percobaan untuk akun ini/
    get kits_path
    assert_redirected_to new_session_path, "tidak boleh sempat masuk"
  end

  test "satu akun diblokir tidak memblokir guru lain dari IP yang sama (sekolah satu NAT)" do
    11.times { post session_path, params: { email_address: users(:guru_mapel).email_address, password: "salah" } }
    %i[guru_piket wakil_kurikulum kepala_sekolah guru_mapel_dua].each do |role|
      post session_path, params: { email_address: users(role).email_address, password: "password" }
      assert_redirected_to root_url, "#{role} harus tetap bisa masuk"
      delete session_path
    end
  end

  test "penulisan email berbeda (huruf besar, spasi) tetap dihitung sebagai akun yang sama" do
    5.times { post session_path, params: { email_address: users(:guru_mapel).email_address.upcase, password: "salah" } }
    6.times { post session_path, params: { email_address: " #{users(:guru_mapel).email_address} ", password: "salah" } }
    post session_path, params: { email_address: users(:guru_mapel).email_address, password: "password" }
    follow_redirect!
    assert_select ".alert--danger", /Terlalu banyak percobaan/
  end

  test "batas longgar per IP menahan serangan massal ke banyak akun" do
    120.times { |i| post session_path, params: { email_address: "akun#{i}@example.test", password: "salah" } }
    post session_path, params: { email_address: users(:guru_piket).email_address, password: "password" }
    follow_redirect!
    assert_select ".alert--danger", /dari jaringan ini/
  end

  test "batas permintaan atur ulang kata sandi per email" do
    6.times { post passwords_path, params: { email_address: "siapa@example.test" } }
    follow_redirect!
    assert_select ".alert--danger", /Terlalu banyak percobaan/
  end

  test "atur ulang kata sandi tidak membocorkan apakah email terdaftar" do
    post passwords_path, params: { email_address: users(:guru_mapel).email_address }
    ok_flash = flash[:notice]
    post passwords_path, params: { email_address: "tidak.ada@example.test" }
    assert_equal ok_flash, flash[:notice]
  end

  test "kembali ke halaman semula setelah masuk hanya ke alamat sendiri (bukan situs lain)" do
    get kits_path
    post session_path, params: { email_address: users(:guru_mapel).email_address, password: "password" }
    assert_redirected_to kits_url
    assert URI(response.location).host == "www.example.com"
  end
end
