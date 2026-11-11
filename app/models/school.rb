# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class School < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :periods, dependent: :destroy
  has_many :school_classes, dependent: :destroy
  has_many :subjects, dependent: :destroy
  has_many :lessons, through: :school_classes

  validates :name, presence: true
  validate :active_days_must_be_valid_weekdays
  validate :active_days_must_cover_scheduled_lessons, on: :update

  private
    def active_days_must_cover_scheduled_lessons
      return unless active_days_changed? && lessons.where.not(day_of_week: Array(active_days)).exists?
      errors.add(:active_days, "tidak boleh menghapus hari yang masih punya jadwal pelajaran")
    end

    def active_days_must_be_valid_weekdays
      days = Array(active_days)
      errors.add(:active_days, :blank) if days.empty?
      errors.add(:active_days, :invalid) unless days.all? { |d| (1..7).cover?(d) } && days.uniq.size == days.size
    end
end
