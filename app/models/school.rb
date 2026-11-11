# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class School < ApplicationRecord
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true
  validate :active_days_must_be_valid_weekdays

  private
    def active_days_must_be_valid_weekdays
      days = Array(active_days)
      errors.add(:active_days, :blank) if days.empty?
      errors.add(:active_days, :invalid) unless days.all? { |d| (1..7).cover?(d) } && days.uniq.size == days.size
    end
end
