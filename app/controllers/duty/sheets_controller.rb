# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Duty
  # Dasar lembar kehadiran dan pengumpulan: simpan per baris (Turbo Frame) dan perbarui ringkasan lewat Turbo Stream.
  # Hanya aktivasi milik guru piket yang sedang login, dan hanya selama belum diselesaikan.
  class SheetsController < BaseController
    before_action :set_activation
    before_action :ensure_open

    def update
      record = records.find(params[:id])
      saved = record.update(record_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(helpers.dom_id(record), partial: row_partial, locals: { activation: @activation, record: record }),
            turbo_stream.replace("sheet-summary", partial: "duty/activations/summary", locals: { summary: @activation.sheet_summary })
          ], status: saved ? :ok : :unprocessable_entity
        end
        format.html { redirect_to duty_activation_path(@activation, anchor: helpers.dom_id(record)) }
      end
    end

    private
      def set_activation
        @activation = current_user.duty_activations.find(params[:activation_id])
      end

      def ensure_open
        head :conflict if @activation.completed?
      end
  end
end
