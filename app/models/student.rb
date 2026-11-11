# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class Student < ApplicationRecord
  belongs_to :school_class
  has_many :attendance_records, dependent: :restrict_with_error
  has_many :submissions, dependent: :restrict_with_error

  normalizes :name, with: ->(n) { n.strip }

  validates :name, presence: true
  validates :roll_number, presence: true, numericality: { only_integer: true, greater_than: 0 },
                          uniqueness: { scope: :school_class_id }

  scope :ordered, -> { order(:roll_number) }
end
