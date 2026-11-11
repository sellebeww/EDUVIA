# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class CurriculumCrudTest < ActionDispatch::IntegrationTest
  setup { log_in_as :wakil_kurikulum }

  # --- Mapel ---
  test "mapel: daftar tampil" do
    get curriculum_subjects_path
    assert_response :success
    assert_select "td", "Matematika"
  end

  test "mapel: tambah valid" do
    assert_difference "Subject.count", 1 do
      post curriculum_subjects_path, params: { subject: { name: "Seni Budaya", code: "sbk" } }
    end
    assert_redirected_to curriculum_subjects_path
    assert_equal "SBK", Subject.find_by(name: "Seni Budaya").code
  end

  test "mapel: tambah tidak valid menampilkan galat berbahasa Indonesia" do
    assert_no_difference "Subject.count" do
      post curriculum_subjects_path, params: { subject: { name: "", code: "MTK" } }
    end
    assert_response :unprocessable_entity
    assert_select ".alert--danger", /perlu diperbaiki/
    assert_select ".alert--danger li", /Nama mapel/
  end

  test "mapel: ubah dan hapus yang tidak dipakai" do
    subject = Subject.create!(school: schools(:smp), name: "Prakarya", code: "PRK")
    patch curriculum_subject_path(subject), params: { subject: { name: "Prakarya Baru" } }
    assert_redirected_to curriculum_subjects_path
    assert_equal "Prakarya Baru", subject.reload.name
    assert_difference "Subject.count", -1 do
      delete curriculum_subject_path(subject)
    end
  end

  test "mapel: yang dipakai jadwal tidak terhapus dan pengguna diberi tahu" do
    assert_no_difference "Subject.count" do
      delete curriculum_subject_path(subjects(:matematika))
    end
    follow_redirect!
    assert_select ".alert--danger", /tidak bisa dihapus/
  end

  test "mapel sekolah lain tidak bisa dibuka atau diubah" do
    get edit_curriculum_subject_path(subjects(:mapel_lain))
    assert_response :not_found
    patch curriculum_subject_path(subjects(:mapel_lain)), params: { subject: { name: "Diretas" } }
    assert_response :not_found
    assert_equal "Matematika", subjects(:mapel_lain).reload.name
  end

  test "mass assignment: school_id dari parameter diabaikan" do
    post curriculum_subjects_path, params: { subject: { name: "Tes", code: "TES", school_id: schools(:lain).id } }
    assert_equal schools(:smp), Subject.find_by(code: "TES").school
  end

  # --- Kelas ---
  test "kelas: tambah dan fase tampil" do
    assert_difference "SchoolClass.count", 1 do
      post curriculum_school_classes_path, params: { school_class: { name: "X IPA", grade_level: 10 } }
    end
    get curriculum_school_classes_path
    assert_select ".badge", "Fase E"
  end

  test "kelas: tingkat tidak valid ditolak" do
    post curriculum_school_classes_path, params: { school_class: { name: "Z", grade_level: 13 } }
    assert_response :unprocessable_entity
  end

  test "kelas: yang punya jadwal tidak bisa dihapus" do
    assert_no_difference "SchoolClass.count" do
      delete curriculum_school_class_path(school_classes(:kelas_7a))
    end
  end

  test "kelas sekolah lain tidak bisa diubah" do
    get edit_curriculum_school_class_path(school_classes(:kelas_lain))
    assert_response :not_found
  end

  # --- Jam pelajaran ---
  test "jam pelajaran: tambah, nomor berikutnya terisi otomatis di formulir" do
    get new_curriculum_period_path
    assert_select "input[name='period[number]'][value='4']"
    assert_difference "Period.count", 1 do
      post curriculum_periods_path, params: { period: { number: 4, starts_at: "08:40", ends_at: "09:20" } }
    end
    assert_equal "08.40–09.20", Period.find_by(number: 4, school: schools(:smp)).time_range
  end

  test "jam pelajaran: selesai sebelum mulai ditolak" do
    post curriculum_periods_path, params: { period: { number: 7, starts_at: "10:00", ends_at: "09:00" } }
    assert_response :unprocessable_entity
  end

  test "jam pelajaran: nomor ganda ditolak" do
    post curriculum_periods_path, params: { period: { number: 1, starts_at: "10:00", ends_at: "10:40" } }
    assert_response :unprocessable_entity
  end

  # --- Jadwal ---
  test "jadwal: grid menampilkan pelajaran, sel kosong, dan istirahat" do
    get curriculum_lessons_path(school_class_id: school_classes(:kelas_7a).id)
    assert_response :success
    assert_select "table.timetable"
    assert_select "a.slot", text: /Matematika/
    assert_select "a.slot--empty"
    assert_select "td", "Istirahat"
    assert_select "th", text: "Senin"
    assert_select "th", text: "Sabtu", count: 0 # bukan hari aktif
  end

  test "jadwal: hari di grid mengikuti hari aktif sekolah" do
    schools(:smp).update!(active_days: [ 1, 2, 3, 4, 5, 6 ])
    get curriculum_lessons_path
    assert_select "th", text: "Sabtu"
  end

  test "jadwal: tanpa kelas menampilkan petunjuk, bukan galat" do
    Lesson.destroy_all
    Kit.destroy_all
    SchoolClass.where(school: schools(:smp)).destroy_all
    get curriculum_lessons_path
    assert_response :success
    assert_select ".empty-state__title", "Lengkapi data dulu"
  end

  test "jadwal: tambah valid" do
    assert_difference "Lesson.count", 1 do
      post curriculum_lessons_path, params: { lesson: lesson_params(day_of_week: 3) }
    end
    assert_redirected_to curriculum_lessons_path(school_class_id: school_classes(:kelas_8a).id)
  end

  test "jadwal: bentrok guru ditolak dengan pesan jelas" do
    assert_no_difference "Lesson.count" do
      post curriculum_lessons_path, params: { lesson: lesson_params(teacher: :guru_mapel, period: :jam_1, day_of_week: 1) }
    end
    assert_response :unprocessable_entity
    assert_select ".alert--danger li", /guru ini/
  end

  test "jadwal: kelas atau guru sekolah lain tidak bisa disisipkan" do
    assert_no_difference "Lesson.count" do
      post curriculum_lessons_path, params: { lesson: lesson_params(school_class: :kelas_lain) }
    end
    assert_response :unprocessable_entity
    assert_no_difference "Lesson.count" do
      post curriculum_lessons_path, params: { lesson: lesson_params(teacher: :guru_lain) }
    end
    assert_response :unprocessable_entity
  end

  test "jadwal: formulir baru terisi dari sel yang diklik" do
    get new_curriculum_lesson_path(school_class_id: school_classes(:kelas_7a).id, period_id: periods(:jam_2).id, day_of_week: 3)
    assert_select "select[name='lesson[school_class_id]'] option[selected][value='#{school_classes(:kelas_7a).id}']"
    assert_select "select[name='lesson[day_of_week]'] option[selected][value='3']"
  end

  test "jadwal: ubah dan hapus" do
    lesson = lessons(:selasa_jam1_8a)
    patch curriculum_lesson_path(lesson), params: { lesson: lesson_params(day_of_week: 4, period: :jam_1) }
    assert_equal 4, lesson.reload.day_of_week
    assert_difference "Lesson.count", -1 do
      delete curriculum_lesson_path(lesson)
    end
  end

  test "jadwal: tombol hapus berdiri sendiri, tidak bersarang di form ubah" do
    lesson = lessons(:selasa_jam1_8a)
    get edit_curriculum_lesson_path(lesson)
    assert_select "form form", false
    assert_select "form[action='#{curriculum_lesson_path(lesson)}'] input[name=_method][value=delete] ~ button", text: /Hapus jadwal ini/
  end

  test "jadwal: jadwal sekolah lain tidak bisa dibuka" do
    foreign = Lesson.new(school_class: school_classes(:kelas_lain), subject: subjects(:mapel_lain), teacher: users(:guru_lain), period: periods(:jam_lain), day_of_week: 1)
    foreign.save!
    get edit_curriculum_lesson_path(foreign)
    assert_response :not_found
  end

  # --- Penugasan piket ---
  test "piket: halaman menampilkan 14 hari dan menandai yang belum bertugas" do
    get curriculum_duty_assignments_path(from: "2026-11-09")
    assert_response :success
    assert_select "tbody tr", 14
    assert_select ".badge--warn", text: "Belum ada guru piket"
    assert_select "span.muted", text: "Bukan hari aktif sekolah"
  end

  test "piket: tugaskan lalu hapus" do
    assert_difference "DutyAssignment.count", 1 do
      post curriculum_duty_assignments_path, params: { duty_assignment: { user_id: users(:guru_piket).id, date: "2026-11-09" } }
    end
    assert_redirected_to curriculum_duty_assignments_path(from: "2026-11-09")
    get curriculum_duty_assignments_path(from: "2026-11-09")
    assert_select ".chip", /Rina Marlina/
    assert_difference "DutyAssignment.count", -1 do
      delete curriculum_duty_assignment_path(DutyAssignment.last)
    end
  end

  test "piket: ganda, bukan guru piket, guru sekolah lain, dan tanggal rusak ditolak" do
    DutyAssignment.create!(user: users(:guru_piket), date: Date.new(2026, 11, 9))
    [ { user_id: users(:guru_piket).id, date: "2026-11-09" },
      { user_id: users(:guru_mapel).id, date: "2026-11-10" },
      { user_id: users(:guru_lain).id, date: "2026-11-10" },
      { user_id: users(:guru_piket_dua).id, date: "bukan-tanggal" } ].each do |params|
      assert_no_difference "DutyAssignment.count" do
        post curriculum_duty_assignments_path, params: { duty_assignment: params }
      end
      assert_redirected_to curriculum_duty_assignments_path
    end
  end

  # --- Data sekolah ---
  test "data sekolah: tampil dan simpan pengaturan" do
    get curriculum_school_path
    assert_response :success
    assert_select "input[name='school[name]'][value='SMP Negeri 3 Cerdas']"
    patch curriculum_school_path, params: { school: { name: "SMP Baru", active_days: %w[1 2 3 4 5 6] } }
    assert_redirected_to curriculum_school_path
    assert_equal [ 1, 2, 3, 4, 5, 6 ], schools(:smp).reload.active_days
    assert_equal "SMP Baru", schools(:smp).name
  end

  test "data sekolah: tidak boleh menghapus hari yang punya jadwal" do
    patch curriculum_school_path, params: { school: { name: "SMP", active_days: %w[2 3 4 5] } }
    assert_response :unprocessable_entity
    assert_equal [ 1, 2, 3, 4, 5 ], schools(:smp).reload.active_days
  end

  test "data sekolah: hari tidak valid ditolak" do
    patch curriculum_school_path, params: { school: { name: "SMP", active_days: %w[9] } }
    assert_response :unprocessable_entity
  end

  private
    def lesson_params(overrides = {})
      defaults = { school_class: :kelas_8a, subject: :ipa, teacher: :guru_mapel_dua, period: :jam_2, day_of_week: 3 }
      p = defaults.merge(overrides)
      { school_class_id: school_classes(p[:school_class]).id, subject_id: subjects(p[:subject]).id,
        teacher_id: users(p[:teacher]).id, period_id: periods(p[:period]).id, day_of_week: p[:day_of_week] }
    end
end
