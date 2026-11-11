# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class CreateSchools < ActiveRecord::Migration[8.1]
  def change
    create_table :schools do |t|
      t.string :name, null: false
      # Hari aktif belajar (ISO 1=Senin .. 7=Minggu). Dikonfigurasi per sekolah, bukan hard-code.
      t.integer :active_days, array: true, null: false, default: [ 1, 2, 3, 4, 5 ]

      t.timestamps
    end
  end
end
