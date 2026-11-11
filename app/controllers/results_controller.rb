# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Hasil belajar kembali ke guru pemilik materi: hanya aktivasi dari ketidakhadiran guru yang sedang login.
class ResultsController < ApplicationController
  RESULTS_LIMIT = 50

  require_role :guru_mapel

  def index
    @limit = RESULTS_LIMIT
    @results = Activation.results_for(current_user).with_details.with_stats.order(completed_at: :desc).limit(@limit).to_a
    @total = Activation.results_for(current_user).count
  end

  def show
    @activation = Activation.results_for(current_user).with_details.find(params[:id])
    @submissions = @activation.submissions.joins(:student).includes(:student).order("students.roll_number").to_a
    @attendance = @activation.attendance_records.index_by(&:student_id)
  end
end
