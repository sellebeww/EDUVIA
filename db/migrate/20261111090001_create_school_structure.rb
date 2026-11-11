# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class CreateSchoolStructure < ActiveRecord::Migration[8.1]
  def change
    create_table :periods do |t|
      t.references :school, null: false, foreign_key: true
      t.integer :number, null: false
      t.time :starts_at, null: false
      t.time :ends_at, null: false
      t.string :label
      t.boolean :recess, null: false, default: false # istirahat: tidak ada pelajaran
      t.timestamps
    end
    add_index :periods, %i[school_id number], unique: true
    add_check_constraint :periods, "number > 0", name: "periods_number_positive"
    add_check_constraint :periods, "ends_at > starts_at", name: "periods_time_order"

    create_table :school_classes do |t|
      t.references :school, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :grade_level, null: false
      t.timestamps
    end
    add_index :school_classes, %i[school_id name], unique: true
    add_check_constraint :school_classes, "grade_level BETWEEN 1 AND 12", name: "school_classes_grade_range"

    create_table :subjects do |t|
      t.references :school, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code, null: false
      t.timestamps
    end
    add_index :subjects, %i[school_id code], unique: true

    create_table :students do |t|
      t.references :school_class, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :roll_number, null: false
      t.timestamps
    end
    add_index :students, %i[school_class_id roll_number], unique: true
  end
end
