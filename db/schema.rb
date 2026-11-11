# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_11_090004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "absences", force: :cascade do |t|
    t.bigint "teacher_id", null: false
    t.date "date", null: false
    t.string "reason", null: false
    t.string "note"
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_absences_on_created_by_id"
    t.index ["date"], name: "index_absences_on_date"
    t.index ["teacher_id", "date"], name: "index_absences_on_teacher_id_and_date", unique: true
    t.index ["teacher_id"], name: "index_absences_on_teacher_id"
  end

  create_table "activations", force: :cascade do |t|
    t.bigint "absence_id", null: false
    t.bigint "lesson_id", null: false
    t.bigint "kit_id"
    t.bigint "invigilator_id"
    t.datetime "activated_at", null: false
    t.datetime "completed_at"
    t.boolean "reused", default: false, null: false
    t.string "warning_codes", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["absence_id", "lesson_id"], name: "index_activations_on_absence_id_and_lesson_id", unique: true
    t.index ["absence_id"], name: "index_activations_on_absence_id"
    t.index ["activated_at"], name: "index_activations_on_activated_at"
    t.index ["invigilator_id", "completed_at"], name: "index_activations_on_invigilator_id_and_completed_at"
    t.index ["invigilator_id"], name: "index_activations_on_invigilator_id"
    t.index ["kit_id"], name: "index_activations_on_kit_id"
    t.index ["kit_id"], name: "index_activations_one_open_per_kit", unique: true, where: "((completed_at IS NULL) AND (kit_id IS NOT NULL))"
    t.index ["lesson_id"], name: "index_activations_on_lesson_id"
  end

  create_table "attendance_records", force: :cascade do |t|
    t.bigint "activation_id", null: false
    t.bigint "student_id", null: false
    t.string "status", default: "hadir", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activation_id", "student_id"], name: "index_attendance_records_on_activation_id_and_student_id", unique: true
    t.index ["activation_id"], name: "index_attendance_records_on_activation_id"
    t.index ["student_id"], name: "index_attendance_records_on_student_id"
    t.check_constraint "status::text = ANY (ARRAY['hadir'::character varying, 'tidak_hadir'::character varying]::text[])", name: "attendance_status_values"
  end

  create_table "duty_assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_duty_assignments_on_date"
    t.index ["user_id", "date"], name: "index_duty_assignments_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_duty_assignments_on_user_id"
  end

  create_table "kits", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "subject_id", null: false
    t.bigint "school_class_id", null: false
    t.string "title", null: false
    t.string "phase", null: false
    t.integer "duration_minutes", default: 35, null: false
    t.text "supervisor_instructions", null: false
    t.text "answer_key"
    t.string "status", default: "disiapkan", null: false
    t.integer "times_used", default: 0, null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_class_id"], name: "index_kits_on_school_class_id"
    t.index ["subject_id", "school_class_id", "status"], name: "index_kits_on_subject_id_and_school_class_id_and_status"
    t.index ["subject_id"], name: "index_kits_on_subject_id"
    t.index ["user_id", "status"], name: "index_kits_on_user_id_and_status"
    t.index ["user_id"], name: "index_kits_on_user_id"
    t.check_constraint "duration_minutes >= 30 AND duration_minutes <= 40", name: "kits_duration_range"
    t.check_constraint "status::text = ANY (ARRAY['disiapkan'::character varying, 'aktif'::character varying, 'terpakai'::character varying]::text[])", name: "kits_status_values"
  end

  create_table "lessons", force: :cascade do |t|
    t.bigint "school_class_id", null: false
    t.bigint "subject_id", null: false
    t.bigint "teacher_id", null: false
    t.bigint "period_id", null: false
    t.integer "day_of_week", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["period_id"], name: "index_lessons_on_period_id"
    t.index ["school_class_id", "day_of_week", "period_id"], name: "index_lessons_unique_class_slot", unique: true
    t.index ["school_class_id"], name: "index_lessons_on_school_class_id"
    t.index ["subject_id"], name: "index_lessons_on_subject_id"
    t.index ["teacher_id", "day_of_week", "period_id"], name: "index_lessons_unique_teacher_slot", unique: true
    t.index ["teacher_id"], name: "index_lessons_on_teacher_id"
    t.check_constraint "day_of_week >= 1 AND day_of_week <= 7", name: "lessons_day_range"
  end

  create_table "periods", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.integer "number", null: false
    t.time "starts_at", null: false
    t.time "ends_at", null: false
    t.string "label"
    t.boolean "recess", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "number"], name: "index_periods_on_school_id_and_number", unique: true
    t.index ["school_id"], name: "index_periods_on_school_id"
    t.check_constraint "ends_at > starts_at", name: "periods_time_order"
    t.check_constraint "number > 0", name: "periods_number_positive"
  end

  create_table "school_classes", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "name", null: false
    t.integer "grade_level", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "name"], name: "index_school_classes_on_school_id_and_name", unique: true
    t.index ["school_id"], name: "index_school_classes_on_school_id"
    t.check_constraint "grade_level >= 1 AND grade_level <= 12", name: "school_classes_grade_range"
  end

  create_table "schools", force: :cascade do |t|
    t.string "name", null: false
    t.integer "active_days", default: [1, 2, 3, 4, 5], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "students", force: :cascade do |t|
    t.bigint "school_class_id", null: false
    t.string "name", null: false
    t.integer "roll_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_class_id", "roll_number"], name: "index_students_on_school_class_id_and_roll_number", unique: true
    t.index ["school_class_id"], name: "index_students_on_school_class_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "code"], name: "index_subjects_on_school_id_and_code", unique: true
    t.index ["school_id"], name: "index_subjects_on_school_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.bigint "activation_id", null: false
    t.bigint "student_id", null: false
    t.boolean "submitted", default: false, null: false
    t.integer "score"
    t.string "note"
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activation_id", "student_id"], name: "index_submissions_on_activation_id_and_student_id", unique: true
    t.index ["activation_id"], name: "index_submissions_on_activation_id"
    t.index ["student_id"], name: "index_submissions_on_student_id"
    t.check_constraint "score IS NULL OR score >= 0 AND score <= 100", name: "submissions_score_range"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "name", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["school_id", "role"], name: "index_users_on_school_id_and_role"
    t.index ["school_id"], name: "index_users_on_school_id"
  end

  add_foreign_key "absences", "users", column: "created_by_id"
  add_foreign_key "absences", "users", column: "teacher_id"
  add_foreign_key "activations", "absences"
  add_foreign_key "activations", "kits"
  add_foreign_key "activations", "lessons"
  add_foreign_key "activations", "users", column: "invigilator_id"
  add_foreign_key "attendance_records", "activations"
  add_foreign_key "attendance_records", "students"
  add_foreign_key "duty_assignments", "users"
  add_foreign_key "kits", "school_classes"
  add_foreign_key "kits", "subjects"
  add_foreign_key "kits", "users"
  add_foreign_key "lessons", "periods"
  add_foreign_key "lessons", "school_classes"
  add_foreign_key "lessons", "subjects"
  add_foreign_key "lessons", "users", column: "teacher_id"
  add_foreign_key "periods", "schools"
  add_foreign_key "school_classes", "schools"
  add_foreign_key "sessions", "users"
  add_foreign_key "students", "school_classes"
  add_foreign_key "subjects", "schools"
  add_foreign_key "submissions", "activations"
  add_foreign_key "submissions", "students"
  add_foreign_key "users", "schools"
end
