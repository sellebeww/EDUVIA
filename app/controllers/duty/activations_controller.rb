# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Duty
  # Halaman guru piket. Hanya aktivasi yang ditugaskan kepada pengguna yang bisa dibuka (selain itu 404).
  class ActivationsController < BaseController
    def index
      @activations = current_user.duty_activations.from_date(Date.current).with_details.ordered_by_slot.to_a
    end

    def show
      @activation = current_user.duty_activations.with_details.find(params[:id])
      @attendance = @activation.attendance_records.joins(:student).includes(:student).order("students.roll_number").to_a
      @submissions = @activation.submissions.joins(:student).includes(:student).order("students.roll_number").to_a
      @summary = @activation.sheet_summary
    end

    def complete
      activation = current_user.duty_activations.find(params[:id])
      result = Activations::Complete.call(activation: activation, actor: current_user)
      if result.ok?
        redirect_to duty_activation_path(activation), notice: result.already ? "Aktivasi ini sudah diselesaikan sebelumnya." : "Selesai. Hasil dikirim ke guru mapel."
      else
        redirect_to duty_activation_path(activation), alert: result.error
      end
    end

    def worksheet
      kit = current_user.duty_activations.find(params[:id]).kit
      return head :not_found unless kit&.worksheet&.attached?
      send_data kit.worksheet.download, filename: kit.worksheet.filename.to_s, type: "application/pdf", disposition: "attachment"
    end
  end
end
