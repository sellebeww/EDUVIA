# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Jam pelajaran (jam ke-N) yang dikonfigurasi per sekolah, termasuk istirahat.
class Period < ApplicationRecord
  belongs_to :school
  has_many :lessons, dependent: :restrict_with_error

  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 },
                     uniqueness: { scope: :school_id }
  validates :starts_at, :ends_at, presence: true
  validate :ends_after_starts

  scope :ordered, -> { order(:number) }
  scope :teaching, -> { where(recess: false) }

  def display_name
    label.presence || (recess? ? "Istirahat" : "Jam ke-#{number}")
  end

  def time_range
    "#{starts_at.strftime('%H.%M')}–#{ends_at.strftime('%H.%M')}"
  end

  private
    def ends_after_starts
      errors.add(:ends_at, :greater_than, count: I18n.l(starts_at, format: "%H.%M")) if starts_at && ends_at && ends_at <= starts_at
    end
end
