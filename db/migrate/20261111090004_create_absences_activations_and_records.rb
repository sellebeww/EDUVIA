# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class CreateAbsencesActivationsAndRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :absences do |t|
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.date :date, null: false
      t.string :reason, null: false
      t.string :note
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :absences, %i[teacher_id date], unique: true
    add_index :absences, :date

    create_table :activations do |t|
      t.references :absence, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.references :kit, foreign_key: true # kosong = tidak ada kit (mode cadangan)
      t.references :invigilator, foreign_key: { to_table: :users } # kosong = belum ada guru piket
      t.datetime :activated_at, null: false
      t.datetime :completed_at
      t.boolean :reused, null: false, default: false
      t.string :warning_codes, array: true, null: false, default: []
      t.timestamps
    end
    # Idempotensi: satu jam pelajaran dari satu ketidakhadiran hanya diaktifkan sekali.
    add_index :activations, %i[absence_id lesson_id], unique: true
    # Satu kit tidak bisa aktif di dua tempat sekaligus.
    add_index :activations, :kit_id, unique: true, where: "completed_at IS NULL AND kit_id IS NOT NULL", name: "index_activations_one_open_per_kit"
    add_index :activations, %i[invigilator_id completed_at]
    add_index :activations, :activated_at

    create_table :attendance_records do |t|
      t.references :activation, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.string :status, null: false, default: "hadir"
      t.timestamps
    end
    add_index :attendance_records, %i[activation_id student_id], unique: true
    add_check_constraint :attendance_records, "status IN ('hadir', 'tidak_hadir')", name: "attendance_status_values"

    create_table :submissions do |t|
      t.references :activation, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.boolean :submitted, null: false, default: false
      t.integer :score
      t.string :note
      t.datetime :submitted_at
      t.timestamps
    end
    add_index :submissions, %i[activation_id student_id], unique: true
    add_check_constraint :submissions, "score IS NULL OR score BETWEEN 0 AND 100", name: "submissions_score_range"
  end
end
