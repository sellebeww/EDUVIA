# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class Subject < ApplicationRecord
  belongs_to :school
  has_many :lessons, dependent: :restrict_with_error
  has_many :kits, dependent: :restrict_with_error

  normalizes :name, with: ->(n) { n.strip }
  normalizes :code, with: ->(c) { c.strip.upcase }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :school_id }

  scope :ordered, -> { order(:name) }
end
