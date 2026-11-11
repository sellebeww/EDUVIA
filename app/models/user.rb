# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class User < ApplicationRecord
  ROLES = %w[guru_mapel guru_piket wakil_kurikulum kepala_sekolah].freeze
  ROLE_LABELS = {
    "guru_mapel" => "Guru Mapel",
    "guru_piket" => "Guru Piket",
    "wakil_kurikulum" => "Wakil Kurikulum",
    "kepala_sekolah" => "Kepala Sekolah"
  }.freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :school
  has_many :lessons, foreign_key: :teacher_id, inverse_of: :teacher, dependent: :restrict_with_error
  has_many :kits, dependent: :restrict_with_error
  has_many :duty_assignments, dependent: :destroy
  has_many :absences, foreign_key: :teacher_id, inverse_of: :teacher, dependent: :restrict_with_error
  has_many :duty_activations, class_name: "Activation", foreign_key: :invigilator_id, inverse_of: :invigilator, dependent: :nullify

  enum :role, ROLES.index_with(&:itself), validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.strip }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def role_label = ROLE_LABELS.fetch(role)
end
