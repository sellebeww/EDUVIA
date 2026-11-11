# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class Submission < ApplicationRecord
  belongs_to :activation
  belongs_to :student

  validates :student_id, uniqueness: { scope: :activation_id }
  validates :score, numericality: { only_integer: true, in: 0..100 }, allow_nil: true
  validates :note, length: { maximum: 200 }
  validate :student_must_be_in_lesson_class

  before_save :stamp_submitted_at

  private
    def stamp_submitted_at
      self.submitted_at = submitted? ? (submitted_at || Time.current) : nil
    end

    def student_must_be_in_lesson_class
      errors.add(:student, "bukan siswa kelas ini") if student && activation && student.school_class_id != activation.lesson.school_class_id
    end
end
