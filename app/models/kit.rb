# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Kit siaga: tugas mandiri + kunci jawaban + petunjuk pengawas, milik satu guru untuk satu mapel di satu kelas.
#
# Status berpindah hanya lewat method di bawah:
#   disiapkan --activate!--> aktif --complete!--> terpakai --reuse!--> aktif
# Transisi lain melempar Kit::InvalidTransition.
class Kit < ApplicationRecord
  class InvalidTransition < StandardError; end

  MAX_WORKSHEET_SIZE = 5.megabytes

  STATUS_LABELS = { "disiapkan" => "Disiapkan", "aktif" => "Aktif", "terpakai" => "Terpakai" }.freeze

  belongs_to :user
  belongs_to :subject
  belongs_to :school_class
  has_many :activations, dependent: :restrict_with_error
  has_one_attached :worksheet

  enum :status, STATUS_LABELS.keys.index_with(&:itself), default: "disiapkan", validate: true

  normalizes :title, with: ->(t) { t.strip }

  before_validation :derive_phase

  validates :title, presence: true, length: { maximum: 120 }
  validates :supervisor_instructions, presence: true
  validates :duration_minutes, presence: true, numericality: { only_integer: true, in: 30..40 }
  validate :owner_must_be_subject_teacher
  validate :owner_must_teach_subject_in_class
  validate :worksheet_must_be_pdf

  scope :by_subject, ->(id) { id.present? ? where(subject_id: id) : all }
  scope :by_class, ->(id) { id.present? ? where(school_class_id: id) : all }
  scope :by_phase, ->(phase) { phase.present? ? where(phase: phase) : all }
  scope :recent, -> { order(updated_at: :desc) }

  def status_label = STATUS_LABELS.fetch(status)

  # Kit yang sedang dipakai di kelas tidak boleh diubah atau dihapus.
  def editable? = !aktif?

  def activate!
    transition!(from: "disiapkan", to: "aktif")
  end

  def complete!
    transition!(from: "aktif", to: "terpakai") do
      self.times_used += 1
      self.last_used_at = Time.current
    end
  end

  # Pakai ulang kit yang sudah terpakai. Penanda pemakaian ulang disimpan di Activation#reused.
  def reuse!
    transition!(from: "terpakai", to: "aktif")
  end

  private
    def transition!(from:, to:)
      with_lock do
        raise InvalidTransition, "Kit #{status} tidak bisa diubah ke #{to}" unless status == from
        yield if block_given?
        self.status = to
        save!
      end
      self
    end

    def derive_phase
      self.phase = school_class&.phase
    end

    # Hanya memeriksa lampiran yang baru diunggah: tipe, ukuran, dan magic byte "%PDF-".
    # Content-type dari klien (dan dari Marcel untuk berkas teks) bisa dipalsukan, jadi isi berkas dicek langsung.
    def worksheet_must_be_pdf
      change = attachment_changes["worksheet"]
      blob = change&.blob
      return unless blob
      errors.add(:worksheet, "maksimal #{MAX_WORKSHEET_SIZE / 1.megabyte} MB") if blob.byte_size > MAX_WORKSHEET_SIZE
      errors.add(:worksheet, "harus berupa berkas PDF") unless blob.content_type == "application/pdf" && pdf_signature?(change.attachable)
    end

    def pdf_signature?(attachable)
      io = case attachable
      when ActiveStorage::Blob then return true # sudah divalidasi saat pertama diunggah (mis. salinan kit)
      when Hash then attachable[:io]
      else attachable.respond_to?(:tempfile) ? attachable.tempfile : attachable
      end
      return false unless io.respond_to?(:read)
      io.rewind
      head = io.read(5)
      io.rewind
      head == "%PDF-"
    end

    def owner_must_be_subject_teacher
      errors.add(:user, "harus berperan Guru Mapel") if user && !user.guru_mapel?
    end

    def owner_must_teach_subject_in_class
      return unless user && subject && school_class
      unless Lesson.exists?(teacher_id: user.id, subject_id: subject.id, school_class_id: school_class.id)
        errors.add(:base, "Anda tidak mengajar mapel ini di kelas tersebut")
      end
    end
end
