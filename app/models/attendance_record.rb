# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class AttendanceRecord < ApplicationRecord
  STATUS_LABELS = { "hadir" => "Hadir", "tidak_hadir" => "Tidak hadir" }.freeze

  belongs_to :activation
  belongs_to :student

  enum :status, STATUS_LABELS.keys.index_with(&:itself), default: "hadir", validate: true

  validates :student_id, uniqueness: { scope: :activation_id }
  validate :student_must_be_in_lesson_class

  private
    def student_must_be_in_lesson_class
      errors.add(:student, "bukan siswa kelas ini") if student && activation && student.school_class_id != activation.lesson.school_class_id
    end
end
