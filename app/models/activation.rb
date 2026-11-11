# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Satu jam pelajaran kelas kosong yang ditangani: menghubungkan ketidakhadiran, jadwal, kit, dan guru piket.
class Activation < ApplicationRecord
  WARNINGS = {
    "no_kit" => "Tidak ada kit untuk jam ini, memakai mode cadangan",
    "no_invigilator" => "Belum ada guru piket yang ditugaskan",
    "concurrent_conflict" => "Guru piket yang sama menangani kelas lain pada jam yang sama"
  }.freeze

  belongs_to :absence
  belongs_to :lesson
  belongs_to :kit, optional: true
  belongs_to :invigilator, class_name: "User", optional: true
  has_many :attendance_records, dependent: :destroy
  has_many :submissions, dependent: :destroy

  delegate :date, to: :absence
  delegate :school_class, :subject, :period, to: :lesson

  validates :activated_at, presence: true
  validates :lesson_id, uniqueness: { scope: :absence_id }
  validate :warning_codes_must_be_known
  validate :invigilator_must_be_duty_teacher
  validate :lesson_must_belong_to_absent_teacher
  validate :kit_must_match_lesson
  validate :completed_after_activated

  scope :open, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :within, ->(range) { where(activated_at: range) }
  scope :for_school, ->(school) { joins(lesson: :school_class).where(school_classes: { school_id: school.id }) }
  scope :from_date, ->(date) { joins(:absence).where("absences.date >= ?", date) }
  scope :ordered_by_slot, -> { joins(:absence, lesson: :period).order("absences.date", "periods.number") }
  scope :results_for, ->(teacher) { completed.joins(:absence).where(absences: { teacher_id: teacher.id }) }
  # Hitungan lembar langsung di SQL (satu query, tanpa N+1) untuk daftar hasil.
  scope :with_stats, -> {
    select("activations.*",
           "(SELECT COUNT(*) FROM attendance_records ar WHERE ar.activation_id = activations.id) AS students_count",
           "(SELECT COUNT(*) FROM attendance_records ar WHERE ar.activation_id = activations.id AND ar.status = 'hadir') AS present_count",
           "(SELECT COUNT(*) FROM submissions sb WHERE sb.activation_id = activations.id AND sb.submitted) AS submitted_count",
           "(SELECT ROUND(AVG(sb.score)) FROM submissions sb WHERE sb.activation_id = activations.id AND sb.score IS NOT NULL) AS average_score")
  }
  scope :with_details, -> { includes(:kit, :invigilator, absence: :teacher, lesson: %i[subject school_class period]) }

  def completed? = completed_at.present?

  # Ringkasan lembar kehadiran dan pengumpulan (dua query ringan). Untuk daftar, pakai scope with_stats.
  def sheet_summary
    attendance = attendance_records.group(:status).count
    { total: attendance.values.sum, present: attendance.fetch("hadir", 0), submitted: submissions.where(submitted: true).count }
  end

  def label = "#{school_class.name} · #{subject.name}"
  def slot_label = "#{period.display_name} · #{period.time_range}"

  # :selesai | :menunggu_piket | :aktif
  def status
    return :selesai if completed?
    invigilator_id ? :aktif : :menunggu_piket
  end

  def warnings = warning_codes.filter_map { |code| WARNINGS[code] }

  private
    def warning_codes_must_be_known
      unknown = warning_codes - WARNINGS.keys
      errors.add(:warning_codes, :invalid) if unknown.any?
    end

    def invigilator_must_be_duty_teacher
      errors.add(:invigilator, "harus berperan Guru Piket") if invigilator && !invigilator.guru_piket?
    end

    def lesson_must_belong_to_absent_teacher
      errors.add(:lesson, "bukan jam mengajar guru yang berhalangan") if lesson && absence && lesson.teacher_id != absence.teacher_id
    end

    def kit_must_match_lesson
      return unless kit && lesson
      errors.add(:kit, "tidak cocok dengan mapel dan kelas jam ini") unless kit.subject_id == lesson.subject_id && kit.school_class_id == lesson.school_class_id
    end

    def completed_after_activated
      errors.add(:completed_at, "tidak boleh sebelum waktu aktif") if completed_at && activated_at && completed_at < activated_at
    end
end
