# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Curriculum
  class LessonsController < ResourceController
    def index
      @classes = current_school.school_classes.ordered.to_a
      @school_class = @classes.find { |c| c.id == params[:school_class_id].to_i } || @classes.first
      @periods = current_school.periods.ordered.to_a
      @days = current_school.active_days.sort
      @grid = @school_class ? @school_class.lessons.includes(:subject, :teacher).index_by { |l| [ l.day_of_week, l.period_id ] } : {}
    end

    private
      def collection = Lesson.where(school_class: current_school.school_classes)
      def resource_label = "Jadwal"

      def build_record(attrs = {})
        Lesson.new(attrs.respond_to?(:to_h) ? attrs.to_h : attrs)
      end

      # ID kiriman diselesaikan lewat data sekolah ini, jadi ID sekolah lain menjadi kosong
      # dan ditolak validasi ("harus ada"), bukan menyimpan data lintas sekolah.
      def permitted_params
        p = params.expect(lesson: %i[school_class_id subject_id teacher_id period_id day_of_week])
        {
          school_class: current_school.school_classes.find_by(id: p[:school_class_id]),
          subject: current_school.subjects.find_by(id: p[:subject_id]),
          teacher: current_school.users.guru_mapel.find_by(id: p[:teacher_id]),
          period: current_school.periods.find_by(id: p[:period_id]),
          day_of_week: p[:day_of_week]
        }
      end

      def default_attributes
        params.permit(:school_class_id, :period_id, :day_of_week).to_h.then do |p|
          { school_class: current_school.school_classes.find_by(id: p[:school_class_id]),
            period: current_school.periods.find_by(id: p[:period_id]),
            day_of_week: p[:day_of_week] }
        end
      end

      def after_save_path
        class_id = @record&.school_class_id
        curriculum_lessons_path(school_class_id: class_id)
      end
  end
end
