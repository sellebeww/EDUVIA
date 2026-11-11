# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class CreateKits < ActiveRecord::Migration[8.1]
  def change
    create_table :kits do |t|
      t.references :user, null: false, foreign_key: true # guru pemilik
      t.references :subject, null: false, foreign_key: true
      t.references :school_class, null: false, foreign_key: true
      t.string :title, null: false
      t.string :phase, null: false # A..F, diturunkan dari tingkat kelas
      t.integer :duration_minutes, null: false, default: 35
      t.text :supervisor_instructions, null: false
      t.text :answer_key
      t.string :status, null: false, default: "disiapkan"
      t.integer :times_used, null: false, default: 0
      t.datetime :last_used_at
      t.timestamps
    end
    add_index :kits, %i[subject_id school_class_id status]
    add_index :kits, %i[user_id status]
    add_check_constraint :kits, "duration_minutes BETWEEN 30 AND 40", name: "kits_duration_range"
    add_check_constraint :kits, "status IN ('disiapkan', 'aktif', 'terpakai')", name: "kits_status_values"
  end
end
