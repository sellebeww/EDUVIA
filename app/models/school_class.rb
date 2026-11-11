# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class SchoolClass < ApplicationRecord
  # Fase kurikulum diturunkan dari tingkat kelas.
  PHASES = { 1..2 => "A", 3..4 => "B", 5..6 => "C", 7..9 => "D", 10..10 => "E", 11..12 => "F" }.freeze

  belongs_to :school
  has_many :students, dependent: :destroy
  has_many :lessons, dependent: :restrict_with_error
  has_many :kits, dependent: :restrict_with_error

  normalizes :name, with: ->(n) { n.strip }

  validates :name, presence: true, uniqueness: { scope: :school_id }
  validates :grade_level, presence: true, numericality: { only_integer: true, in: 1..12 }

  scope :ordered, -> { order(:grade_level, :name) }

  def phase
    PHASES.find { |range, _| range.cover?(grade_level) }&.last
  end
end
