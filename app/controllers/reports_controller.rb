# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Laporan bulanan. Untuk kepala sekolah (satu-satunya halaman mereka) dan wakil kurikulum.
class ReportsController < ApplicationController
  require_role :kepala_sekolah, :wakil_kurikulum

  def index
    redirect_to report_path(Date.current.strftime("%Y-%m"))
  end

  def show
    month = parse_month(params[:id]) or return head :not_found
    @report = Reports::Monthly.new(school: current_user.school, month: month)
    @prev_month = month << 1
    @next_month = month >> 1 if month < Date.current.beginning_of_month
  end

  private
    def parse_month(value)
      Date.strptime(value.to_s, "%Y-%m") if value.to_s.match?(/\A\d{4}-(0[1-9]|1[0-2])\z/)
    rescue Date::Error
      nil
    end
end
