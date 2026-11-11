# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Curriculum
  class DutyAssignmentsController < BaseController
    RANGE_DAYS = 14

    def index
      @from = parse_date(params[:from]) || Date.current
      @to = @from + (RANGE_DAYS - 1)
      @by_date = scope.between(@from, @to).includes(:user).group_by(&:date)
      @duty_teachers = current_school.users.guru_piket.order(:name)
      @assignment = DutyAssignment.new(date: @from)
    end

    def create
      user = current_school.users.guru_piket.find_by(id: params.dig(:duty_assignment, :user_id))
      @assignment = DutyAssignment.new(user: user, date: parse_date(params.dig(:duty_assignment, :date)))
      if @assignment.save
        redirect_to curriculum_duty_assignments_path(from: @assignment.date), notice: "Guru piket berhasil ditugaskan."
      else
        redirect_to curriculum_duty_assignments_path, alert: @assignment.errors.full_messages.to_sentence
      end
    end

    def destroy
      assignment = scope.find(params[:id])
      assignment.destroy!
      redirect_to curriculum_duty_assignments_path(from: assignment.date), notice: "Penugasan piket dihapus.", status: :see_other
    end

    private
      def scope = DutyAssignment.where(user: current_school.users.guru_piket)

      def parse_date(value)
        Date.iso8601(value.to_s)
      rescue Date::Error
        nil
      end
  end
end
