# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class SessionsController < ApplicationController
  # Batas percobaan masuk memakai store sendiri (bukan cache aplikasi) supaya selalu aktif di semua lingkungan.
  # shortcut: memori per proses; untuk banyak server pakai store bersama (mis. Solid Cache).
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

  allow_unauthenticated_access only: %i[ new create ]
  # Dua lapis: ketat per akun+IP (menahan tebak sandi satu akun) dan longgar per IP (menahan serangan massal).
  # Per-IP saja tidak cukup: banyak guru masuk bersamaan dari satu IP sekolah (NAT) dan tidak boleh saling memblokir.
  rate_limit to: 10, within: 3.minutes, only: :create, store: RATE_LIMIT_STORE, name: "per-akun",
             by: -> { "#{request.remote_ip}|#{params[:email_address].to_s.strip.downcase}" },
             with: -> { redirect_to new_session_path, alert: "Terlalu banyak percobaan untuk akun ini. Coba lagi beberapa menit lagi." }
  rate_limit to: 120, within: 3.minutes, only: :create, store: RATE_LIMIT_STORE, name: "per-ip",
             with: -> { redirect_to new_session_path, alert: "Terlalu banyak percobaan masuk dari jaringan ini. Coba lagi beberapa menit lagi." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Email atau kata sandi salah."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
