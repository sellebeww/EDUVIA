# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

# Guru piket mengisi lembar, menyelesaikan; hasil kembali ke guru mapel.
class SheetsFlowTest < ActionDispatch::IntegrationTest
  MONDAY = Date.new(2026, 11, 9)
  TURBO = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  setup do
    travel_to Time.zone.local(2026, 11, 9, 7, 0)
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY)
    DutyAssignment.create!(user: users(:guru_piket_dua), date: MONDAY)
    Activations::Create.call(actor: users(:wakil_kurikulum), teacher: users(:guru_mapel), date: MONDAY, reason: "sakit", today: MONDAY)
    @activation = Activation.find_by(lesson: lessons(:senin_jam1_7a))
    @piket = login_session(@activation.invigilator == users(:guru_piket) ? :guru_piket : :guru_piket_dua)
    @record = @activation.attendance_records.joins(:student).find_by(students: { roll_number: 1 })
    @submission = @activation.submissions.joins(:student).find_by(students: { roll_number: 1 })
  end

  def other_piket = login_session(@activation.invigilator == users(:guru_piket) ? :guru_piket_dua : :guru_piket)

  # --- lembar tampil ---
  test "halaman aktivasi menampilkan lembar per siswa dan ringkasan" do
    @piket.get duty_activation_path(@activation)
    assert_equal 200, @piket.response.status
    @piket.assert_select "#sheet-summary", /Hadir 3 dari 3/
    @piket.assert_select "#sheet-summary", /Mengumpulkan 0 dari 3/
    @piket.assert_select "ul.sheet-list", 2
    @piket.assert_select ".sheets__cols > div:first-child ul.sheet-list turbo-frame", 3 # lembar kehadiran
    @piket.assert_select ".sheets__cols > div:last-child ul.sheet-list turbo-frame", 3 # lembar pengumpulan
    @piket.assert_select "turbo-frame#attendance_record_#{@record.id} input[type=radio][checked][value=hadir]"
    @piket.assert_select "turbo-frame#submission_#{@submission.id} input[type=number][name='submission[score]']"
    @piket.assert_select "form[data-controller='autosave']", minimum: 6
    @piket.assert_select "button", /Selesai dan kirim hasil ke guru/
  end

  # --- kehadiran ---
  test "simpan kehadiran per baris: Turbo Stream mengganti baris dan ringkasan" do
    @piket.patch duty_activation_attendance_record_path(@activation, @record), params: { attendance_record: { status: "tidak_hadir" } }, headers: TURBO
    assert_equal 200, @piket.response.status
    assert_equal "text/vnd.turbo-stream.html", @piket.response.media_type
    body = @piket.response.body
    assert_includes body, %(action="replace" target="attendance_record_#{@record.id}")
    assert_includes body, %(action="replace" target="sheet-summary")
    assert_includes body, "Hadir</strong> 2 dari 3"
    assert @record.reload.tidak_hadir?
  end

  test "status kehadiran tidak valid ditolak (422), data tidak berubah, pesan tampil di baris" do
    @piket.patch duty_activation_attendance_record_path(@activation, @record), params: { attendance_record: { status: "izin" } }, headers: TURBO
    assert_equal 422, @piket.response.status
    assert_includes @piket.response.body, "sheet-row__error"
    assert @record.reload.hadir?
  end

  # --- pengumpulan ---
  test "simpan pengumpulan: dikumpulkan, nilai, catatan" do
    @piket.patch duty_activation_submission_path(@activation, @submission), params: { submission: { submitted: "1", score: "85", note: "Rapi" } }, headers: TURBO
    assert_equal 200, @piket.response.status
    assert_includes @piket.response.body, "Mengumpulkan</strong> 1 dari 3"
    @submission.reload
    assert @submission.submitted?
    assert_equal 85, @submission.score
    assert_equal "Rapi", @submission.note
    assert @submission.submitted_at
  end

  test "nilai di luar 0..100 atau bukan angka ditolak" do
    [ "150", "-5", "abc", "7.5" ].each do |bad|
      @piket.patch duty_activation_submission_path(@activation, @submission), params: { submission: { submitted: "1", score: bad } }, headers: TURBO
      assert_equal 422, @piket.response.status, bad
      assert_nil @submission.reload.score, bad
    end
  end

  test "nilai dikosongkan kembali menjadi kosong" do
    @submission.update!(score: 70, submitted: true)
    @piket.patch duty_activation_submission_path(@activation, @submission), params: { submission: { submitted: "1", score: "" } }, headers: TURBO
    assert_nil @submission.reload.score
  end

  test "tanpa JavaScript: permintaan HTML dialihkan kembali ke halaman" do
    @piket.patch duty_activation_attendance_record_path(@activation, @record), params: { attendance_record: { status: "tidak_hadir" } }
    @piket.assert_redirected_to duty_activation_path(@activation, anchor: "attendance_record_#{@record.id}")
    assert @record.reload.tidak_hadir?
  end

  test "parameter terlarang (student_id, activation_id) diabaikan" do
    other_student = students(:bella)
    @piket.patch duty_activation_attendance_record_path(@activation, @record), params: { attendance_record: { status: "tidak_hadir", student_id: students(:dimas).id, activation_id: 0 } }, headers: TURBO
    assert_equal students(:andi), @record.reload.student
    assert_equal @activation.id, @record.activation_id
    assert other_student
  end

  # --- hak akses ---
  test "guru piket lain tidak bisa mengubah lembar yang bukan miliknya" do
    intruder = other_piket
    intruder.patch duty_activation_attendance_record_path(@activation, @record), params: { attendance_record: { status: "tidak_hadir" } }, headers: TURBO
    assert_equal 404, intruder.response.status
    intruder.patch duty_activation_submission_path(@activation, @submission), params: { submission: { submitted: "1" } }, headers: TURBO
    assert_equal 404, intruder.response.status
    intruder.patch complete_duty_activation_path(@activation)
    assert_equal 404, intruder.response.status
    assert @record.reload.hadir?
    assert_not @activation.reload.completed?
  end

  test "baris milik aktivasi lain tidak bisa diubah lewat URL aktivasi sendiri" do
    foreign = Activation.where.not(id: @activation.id).first.attendance_records.first
    skip "tidak ada baris lain" unless foreign
    @piket.patch duty_activation_attendance_record_path(@activation, foreign), params: { attendance_record: { status: "tidak_hadir" } }, headers: TURBO
    assert_equal 404, @piket.response.status
    assert foreign.reload.hadir?
  end

  test "peran selain guru piket ditolak" do
    %i[guru_mapel wakil_kurikulum kepala_sekolah].each do |role|
      session = login_session(role)
      session.patch duty_activation_attendance_record_path(@activation, @record), params: { attendance_record: { status: "tidak_hadir" } }, headers: TURBO
      assert_equal 403, session.response.status, role
      session.patch complete_duty_activation_path(@activation)
      assert_equal 403, session.response.status, role
    end
    assert @record.reload.hadir?
  end

  # --- selesai ---
  test "selesai: kit terpakai, lembar terkunci, hasil sampai ke guru mapel" do
    @piket.patch duty_activation_attendance_record_path(@activation, @record), params: { attendance_record: { status: "tidak_hadir" } }, headers: TURBO
    @piket.patch duty_activation_submission_path(@activation, @submission), params: { submission: { submitted: "1", score: "90" } }, headers: TURBO

    assert_list_broadcasts("teacher_#{users(:guru_mapel).id}", count: 1) do
      @piket.patch complete_duty_activation_path(@activation)
    end
    @piket.assert_redirected_to duty_activation_path(@activation)
    @piket.follow_redirect!
    @piket.assert_select ".alert--ok", /Selesai\./
    assert @activation.reload.completed?
    assert kits(:mtk_7a_siap).reload.terpakai?
    assert_equal 1, kits(:mtk_7a_siap).times_used

    @piket.get duty_activation_path(@activation)
    @piket.assert_select "form[action*='attendance_records']", 0
    @piket.assert_select "button", text: /Selesai dan kirim/, count: 0
    @piket.assert_select ".alert--ok", /Hasil sudah dikirim ke Sari Wulandari/

    @piket.patch duty_activation_attendance_record_path(@activation, @record), params: { attendance_record: { status: "hadir" } }, headers: TURBO
    assert_equal 409, @piket.response.status
    assert @record.reload.tidak_hadir?
  end

  test "selesai dua kali: pesan sudah diselesaikan, tidak ada perubahan" do
    @piket.patch complete_duty_activation_path(@activation)
    @piket.patch complete_duty_activation_path(@activation)
    @piket.follow_redirect!
    @piket.assert_select ".alert--ok", /sudah diselesaikan sebelumnya/
    assert_equal 1, kits(:mtk_7a_siap).reload.times_used
  end

  test "kartu yang sudah selesai tetap tampil di daftar piket sebagai Lihat hasil" do
    @piket.patch complete_duty_activation_path(@activation)
    @piket.get duty_root_path
    @piket.assert_select ".duty-card--done .badge--status-terpakai", "Selesai"
    @piket.assert_select ".duty-card--done a.btn", "Lihat hasil"
  end

  # --- hasil guru mapel ---
  test "hasil: kosong sebelum selesai, lalu muncul di daftar dan detail guru mapel" do
    sari = login_session(:guru_mapel)
    sari.get results_path
    sari.assert_select ".empty-state__title", "Belum ada hasil"

    @piket.patch duty_activation_attendance_record_path(@activation, @record), params: { attendance_record: { status: "tidak_hadir" } }, headers: TURBO
    @piket.patch duty_activation_submission_path(@activation, @submission), params: { submission: { submitted: "1", score: "90", note: "Bagus" } }, headers: TURBO
    @piket.patch complete_duty_activation_path(@activation)

    sari.get results_path
    sari.assert_select ".result-card__title", /VII A · Matematika/
    sari.assert_select ".result-card__stats", /2\/3/
    sari.assert_select ".result-card__stats", /90/
    sari.get result_path(@activation)
    assert_equal 200, sari.response.status
    sari.assert_select "h1", "VII A · Matematika"
    sari.assert_select "tbody tr", 3
    sari.assert_select "td", text: "Bagus"
    sari.assert_select ".badge--status-warn", "Tidak hadir"
    sari.get kits_path
    sari.assert_select "#teacher-live .result-card__title", /VII A · Matematika/
    sari.assert_select "turbo-cable-stream-source", 1
  end

  test "daftar hasil dibatasi dan memberi tahu jumlah yang tidak tampil" do
    @piket.patch complete_duty_activation_path(@activation)
    other = Activation.where.not(id: @activation.id).first
    Activations::Complete.call(activation: other, actor: other.invigilator)
    original = ResultsController::RESULTS_LIMIT
    silence_warnings { ResultsController.const_set(:RESULTS_LIMIT, 1) }
    sari = login_session(:guru_mapel)
    sari.get results_path
    sari.assert_select ".result-card", 1
    sari.assert_select ".muted.center", /Menampilkan 1 hasil terbaru dari 2/
  ensure
    silence_warnings { ResultsController.const_set(:RESULTS_LIMIT, original) } if original
  end

  test "hasil guru lain tidak bisa dibuka; peran lain ditolak" do
    @piket.patch complete_duty_activation_path(@activation)
    budi = login_session(:guru_mapel_dua)
    budi.get result_path(@activation)
    assert_equal 404, budi.response.status
    budi.get results_path
    budi.assert_select ".result-card", 0
    %i[guru_piket wakil_kurikulum kepala_sekolah].each do |role|
      session = login_session(role)
      session.get results_path
      assert_equal 403, session.response.status, role
    end
  end

  test "aktivasi yang belum selesai tidak muncul sebagai hasil" do
    sari = login_session(:guru_mapel)
    sari.get result_path(@activation)
    assert_equal 404, sari.response.status
  end

  test "hasil mode cadangan (tanpa kit) juga kembali ke guru mapel" do
    no_kit = Activation.find_by(lesson: lessons(:senin_jam2_8a))
    session = login_session(no_kit.invigilator == users(:guru_piket) ? :guru_piket : :guru_piket_dua)
    session.patch complete_duty_activation_path(no_kit)
    sari = login_session(:guru_mapel)
    sari.get results_path
    sari.assert_select ".result-card", 1
    sari.assert_select ".result-card .muted", /Mode cadangan/
  end

  test "daftar hasil tidak N+1: jumlah query tetap saat hasil bertambah" do
    sari = login_session(:guru_mapel)
    @piket.patch complete_duty_activation_path(@activation)
    sari.get results_path # pemanasan
    one = count_queries { sari.get results_path }
    Activation.where.not(id: @activation.id).where(invigilator: @activation.invigilator).find_each { |a| Activations::Complete.call(activation: a, actor: a.invigilator) }
    Activation.where.not(id: @activation.id).where(completed_at: nil).find_each { |a| Activations::Complete.call(activation: a, actor: a.invigilator) }
    assert_operator Activation.completed.count, :>=, 2
    assert_equal one, count_queries { sari.get results_path }
  end
end
