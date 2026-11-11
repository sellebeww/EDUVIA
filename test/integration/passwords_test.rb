# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class PasswordsTest < ActionDispatch::IntegrationTest
  test "formulir lupa kata sandi tampil" do
    get new_password_path
    assert_response :success
    assert_select "h1", "Lupa kata sandi?"
  end

  test "email terdaftar menerima petunjuk, pesan sama untuk email tak dikenal" do
    assert_enqueued_emails 1 do
      post passwords_path, params: { email_address: users(:guru_mapel).email_address }
    end
    assert_redirected_to new_session_path

    assert_no_enqueued_emails do
      post passwords_path, params: { email_address: "tidak.ada@example.test" }
    end
    assert_redirected_to new_session_path
  end

  test "token valid mengganti kata sandi" do
    user = users(:guru_mapel)
    put password_path(user.password_reset_token), params: { password: "baru12345", password_confirmation: "baru12345" }
    assert_redirected_to new_session_path
    assert User.authenticate_by(email_address: user.email_address, password: "baru12345")
  end

  test "konfirmasi tidak cocok ditolak" do
    user = users(:guru_mapel)
    token = user.password_reset_token
    put password_path(token), params: { password: "baru12345", password_confirmation: "beda" }
    assert_redirected_to edit_password_path(token)
    assert User.authenticate_by(email_address: user.email_address, password: "password")
  end

  test "token tidak valid ditolak" do
    put password_path("token-ngawur"), params: { password: "x", password_confirmation: "x" }
    assert_redirected_to new_password_path
  end
end
