# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Guru piket yang bertugas pada satu tanggal.
class DutyAssignment < ApplicationRecord
  belongs_to :user

  validates :date, presence: true
  validates :user_id, uniqueness: { scope: :date, message: "sudah bertugas piket pada tanggal ini" }
  validate :user_must_be_duty_teacher

  scope :on, ->(date) { where(date: date) }
  scope :between, ->(from, to) { where(date: from..to) }

  private
    def user_must_be_duty_teacher
      errors.add(:user, "harus berperan Guru Piket") if user && !user.guru_piket?
    end
end
