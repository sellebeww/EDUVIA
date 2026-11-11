# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Guru berhalangan pada satu tanggal. Batas tanggal (hari ini sampai 7 hari ke depan) dijaga oleh Activations::Create.
class Absence < ApplicationRecord
  REASONS = { "sakit" => "Sakit", "izin" => "Izin", "dinas" => "Dinas luar", "lainnya" => "Lainnya" }.freeze

  belongs_to :teacher, class_name: "User"
  belongs_to :created_by, class_name: "User"
  has_many :activations, dependent: :restrict_with_error

  enum :reason, REASONS.keys.index_with(&:itself), validate: true

  validates :date, presence: true
  validates :teacher_id, uniqueness: { scope: :date, message: "sudah ditandai berhalangan pada tanggal ini" }
  validates :note, length: { maximum: 200 }
  validate :teacher_must_be_subject_teacher
  validate :creator_must_be_curriculum_deputy
  validate :date_must_be_school_day

  def reason_label = REASONS.fetch(reason)

  private
    def teacher_must_be_subject_teacher
      errors.add(:teacher, "harus berperan Guru Mapel") if teacher && !teacher.guru_mapel?
    end

    def creator_must_be_curriculum_deputy
      errors.add(:created_by, "harus berperan Wakil Kurikulum") if created_by && !created_by.wakil_kurikulum?
    end

    def date_must_be_school_day
      return unless date && teacher
      errors.add(:date, "bukan hari aktif sekolah") unless teacher.school.active_days.include?(date.cwday)
    end
end
