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

  enum :role, ROLES.index_with(&:itself), validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.strip }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def role_label = ROLE_LABELS.fetch(role)
end
