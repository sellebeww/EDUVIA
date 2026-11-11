# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class CreateLessonsAndDutyAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :lessons do |t|
      t.references :school_class, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.references :period, null: false, foreign_key: true
      t.integer :day_of_week, null: false # ISO: 1=Senin .. 7=Minggu
      t.timestamps
    end
    # Kelas tak bisa dobel jam; guru tak bisa mengajar dua kelas bersamaan.
    add_index :lessons, %i[school_class_id day_of_week period_id], unique: true, name: "index_lessons_unique_class_slot"
    add_index :lessons, %i[teacher_id day_of_week period_id], unique: true, name: "index_lessons_unique_teacher_slot"
    add_check_constraint :lessons, "day_of_week BETWEEN 1 AND 7", name: "lessons_day_range"

    create_table :duty_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.timestamps
    end
    add_index :duty_assignments, %i[user_id date], unique: true
    add_index :duty_assignments, :date
  end
end
