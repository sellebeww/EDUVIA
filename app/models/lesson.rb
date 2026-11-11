# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Satu jam pelajaran dalam jadwal mingguan: kelas + mapel + guru + jam ke-N pada hari tertentu.
class Lesson < ApplicationRecord
  belongs_to :school_class
  belongs_to :subject
  belongs_to :teacher, class_name: "User"
  belongs_to :period
  has_many :activations, dependent: :restrict_with_error

  delegate :school, to: :school_class, allow_nil: true

  validates :day_of_week, presence: true, inclusion: { in: 1..7 }
  validates :period_id, uniqueness: { scope: %i[school_class_id day_of_week], message: "sudah dipakai kelas ini pada hari tersebut" }
  validates :period_id, uniqueness: { scope: %i[teacher_id day_of_week], message: "sudah dipakai guru ini mengajar kelas lain pada hari tersebut" }, if: :teacher_id
  validate :teacher_must_be_subject_teacher
  validate :day_must_be_active
  validate :period_must_be_teaching
  validate :records_must_share_school

  scope :on_weekday, ->(date) { where(day_of_week: date.cwday) }
  scope :by_teacher, ->(user) { where(teacher_id: user.id) }
  scope :chronological, -> { joins(:period).order(:day_of_week, "periods.number") }

  private
    def teacher_must_be_subject_teacher
      errors.add(:teacher, "harus berperan Guru Mapel") if teacher && !teacher.guru_mapel?
    end

    def day_must_be_active
      return unless day_of_week && school
      errors.add(:day_of_week, "bukan hari aktif sekolah") unless school.active_days.include?(day_of_week)
    end

    def period_must_be_teaching
      errors.add(:period, "adalah waktu istirahat") if period&.recess?
    end

    def records_must_share_school
      return unless school_class
      errors.add(:subject, "bukan milik sekolah ini") if subject && subject.school_id != school_class.school_id
      errors.add(:period, "bukan milik sekolah ini") if period && period.school_id != school_class.school_id
      errors.add(:teacher, "bukan dari sekolah ini") if teacher && teacher.school_id != school_class.school_id
    end
end
