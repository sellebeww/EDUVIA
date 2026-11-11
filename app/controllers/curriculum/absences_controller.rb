# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Curriculum
  # Menandai guru berhalangan dan mengaktifkan kit siaga dengan satu tombol.
  # Halaman "new" menampilkan pratinjau (Turbo Frame) memakai rencana yang sama dengan penyimpanan.
  class AbsencesController < BaseController
    def new
      @teachers = current_school.users.guru_mapel.order(:name)
      @teacher = @teachers.find { |t| t.id == params[:teacher_id].to_i }
      @date = parse_date(params[:date])
      @reason = params[:reason].presence_in(Absence::REASONS.keys) || "sakit"
      @note = params[:note].to_s.first(200)
      return unless params.key?(:teacher_id) || params.key?(:date)

      @error = Activations::Create.validation_error(teacher: @teacher, date: @date)
      @plan = Activations::Plan.new(teacher: @teacher, date: @date) unless @error
    end

    def create
      teacher = current_school.users.guru_mapel.find_by(id: params[:teacher_id])
      date = parse_date(params[:date])
      result = Activations::Create.call(actor: current_user, teacher: teacher, date: date, reason: params[:reason], note: params[:note])

      if result.ok?
        flash[:notice] = result.message
        flash[:warnings] = result.warnings if result.warnings.any?
        redirect_to curriculum_root_path
      else
        redirect_to new_curriculum_absence_path(teacher_id: teacher&.id, date: date, reason: params[:reason], note: params[:note]), alert: result.error
      end
    end

    private
      def parse_date(value)
        Date.iso8601(value.to_s)
      rescue Date::Error
        nil
      end
  end
end
