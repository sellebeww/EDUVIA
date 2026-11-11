# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Activations
  # Rencana aktivasi untuk satu guru pada satu tanggal: untuk tiap jam mengajar, kit mana dan guru piket siapa.
  # Tidak menulis ke database. Dipakai oleh pratinjau (halaman) dan oleh Activations::Create (penyimpanan),
  # sehingga yang dilihat wakil kurikulum sama dengan yang akan terjadi.
  class Plan
    Item = Struct.new(:lesson, :existing, :kit, :reused, :invigilator, :warning_codes, keyword_init: true) do
      def existing? = existing.present?
    end

    attr_reader :teacher, :date

    def initialize(teacher:, date:)
      @teacher = teacher
      @date = date
    end

    def lessons
      @lessons ||= teacher.lessons.on_weekday(date).chronological.includes(:subject, :school_class, :period).to_a
    end

    def items
      @items ||= build_items
    end

    def empty? = lessons.empty?

    private
      def build_items
        existing = Activation.joins(:absence).where(absences: { teacher_id: teacher.id, date: date }).index_by(&:lesson_id)
        matcher = Kits::Matcher.new(teacher)
        assigner = Duty::Assigner.new(date: date, school: teacher.school)

        lessons.map do |lesson|
          if (activation = existing[lesson.id])
            Item.new(lesson: lesson, existing: activation, kit: activation.kit, reused: activation.reused,
                     invigilator: activation.invigilator, warning_codes: activation.warning_codes)
          else
            match = matcher.match(lesson)
            pick = assigner.assign(lesson.period_id)
            Item.new(lesson: lesson, kit: match.kit, reused: match.reused, invigilator: pick.user,
                     warning_codes: (match.kit ? [] : [ "no_kit" ]) + pick.warning_codes)
          end
        end
      end
  end
end
