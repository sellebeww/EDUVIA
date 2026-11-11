# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

# Alur inti dengan dua "browser": wakil kurikulum mengaktifkan, guru piket menerima.
class ActivationFlowTest < ActionDispatch::IntegrationTest
  MONDAY = Date.new(2026, 11, 9)

  setup do
    travel_to Time.zone.local(2026, 11, 9, 7, 0)
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY)
    DutyAssignment.create!(user: users(:guru_piket_dua), date: MONDAY)
    @wakur = login_session(:wakil_kurikulum)
  end

  def activate(session = @wakur, overrides = {})
    session.post curriculum_absences_path, params: { teacher_id: users(:guru_mapel).id, date: MONDAY.iso8601, reason: "sakit", note: "" }.merge(overrides)
  end

  # --- pratinjau ---
  test "halaman tandai guru berhalangan tampil" do
    @wakur.get new_curriculum_absence_path
    assert_equal 200, @wakur.response.status
    @wakur.assert_select "h1", "Tandai Guru Berhalangan"
    @wakur.assert_select "select[name='teacher_id'] option", text: "Sari Wulandari"
    @wakur.assert_select "input[type=date][min='2026-11-09'][max='2026-11-16']"
    @wakur.assert_select "turbo-frame#preview"
  end

  test "tanggal bawaan formulir: hari aktif terdekat (Senin bila hari ini Sabtu)" do
    @wakur.get new_curriculum_absence_path
    @wakur.assert_select "input[type=date][value='2026-11-09']" # Senin, hari ini
    travel_to Time.zone.local(2026, 11, 14, 9, 0) do # Sabtu
      @wakur.get new_curriculum_absence_path
      @wakur.assert_select "input[type=date][value='2026-11-16']"
    end
  end

  test "pratinjau menampilkan jam terdampak, kit, guru piket, dan tombol aktifkan; tidak menulis data" do
    assert_no_difference [ "Absence.count", "Activation.count" ] do
      @wakur.get new_curriculum_absence_path, params: { teacher_id: users(:guru_mapel).id, date: MONDAY.iso8601, reason: "sakit" }
    end
    @wakur.assert_select "#preview-title", /Sari Wulandari/
    @wakur.assert_select "#preview tbody tr", minimum: 2
    @wakur.assert_select "#preview td", text: /Latihan Pecahan/
    @wakur.assert_select "#preview .badge--warn", text: /Tidak ada kit: mode cadangan/
    @wakur.assert_select "#preview form button", /Aktifkan 2 kelas sekarang/
    assert kits(:mtk_7a_siap).reload.disiapkan?
  end

  test "permintaan Turbo Frame hanya mengembalikan bingkai, tanpa layout" do
    @wakur.get new_curriculum_absence_path, params: { teacher_id: users(:guru_mapel).id, date: MONDAY.iso8601 }, headers: { "Turbo-Frame" => "preview" }
    assert_equal 200, @wakur.response.status
    @wakur.assert_select "turbo-frame#preview"
    @wakur.assert_select "header.site-header", count: 0
  end

  test "pratinjau: tanggal lewat, bukan hari aktif, guru tanpa jam, dan semua sudah aktif" do
    @wakur.get new_curriculum_absence_path, params: { teacher_id: users(:guru_mapel).id, date: "2026-11-08" }
    @wakur.assert_select ".alert--danger", /sudah lewat/
    @wakur.get new_curriculum_absence_path, params: { teacher_id: users(:guru_mapel).id, date: "2026-11-14" }
    @wakur.assert_select ".alert--danger", /bukan hari aktif/
    @wakur.get new_curriculum_absence_path, params: { teacher_id: users(:guru_mapel).id, date: "2026-11-11" }
    @wakur.assert_select ".empty-state__title", "Tidak ada jam mengajar"
    @wakur.get new_curriculum_absence_path, params: { teacher_id: users(:guru_mapel).id, date: "bukan-tanggal" }
    @wakur.assert_select ".alert--danger", /Tanggal belum dipilih/
    activate
    @wakur.get new_curriculum_absence_path, params: { teacher_id: users(:guru_mapel).id, date: MONDAY.iso8601 }
    @wakur.assert_select "#preview", /Semua kelas untuk guru dan tanggal ini sudah diaktifkan/
    @wakur.assert_select "#preview form button", count: 0
  end

  # --- aktivasi ---
  test "aktivasi: kembali ke dashboard dengan ringkasan dan peringatan, daftar terisi" do
    activate
    @wakur.assert_redirected_to curriculum_root_path
    @wakur.follow_redirect!
    @wakur.assert_select ".alert--ok", /2 kelas diaktifkan untuk Sari Wulandari/
    @wakur.assert_select ".alert--warn li", /VIII A · Matematika.*mode cadangan/
    @wakur.assert_select "#curriculum-activations tbody tr[id^='row_activation']", 2
    @wakur.assert_select "#curriculum-activations .badge", text: "Mode cadangan"
    @wakur.assert_select "#curriculum-activations .badge", text: "Aktif"
  end

  test "klik ganda: kedua kali tidak membuat data atau siaran ganda" do
    activate
    assert_no_difference [ "Absence.count", "Activation.count", "AttendanceRecord.count" ] do
      assert_list_broadcasts("curriculum_#{schools(:smp).id}", count: 0) { activate }
    end
    @wakur.follow_redirect!
    @wakur.assert_select ".alert--ok", /sudah diaktifkan sebelumnya/
  end

  test "siaran realtime: kartu dikirim ke guru piket yang tepat saat aktivasi" do
    assert_list_broadcasts("duty_#{users(:guru_piket).id}", count: 1) do
      assert_list_broadcasts("duty_#{users(:guru_piket_dua).id}", count: 1) do
        activate
      end
    end
  end

  test "dua browser: guru piket melihat kartunya, masing-masing hanya miliknya" do
    rina = login_session(:guru_piket)
    hendra = login_session(:guru_piket_dua)
    rina.get duty_root_path
    rina.assert_select ".duty-card", 0
    rina.assert_select ".empty-state__title", "Belum ada kit aktif"

    activate

    rina.get duty_root_path
    hendra.get duty_root_path
    rina.assert_select ".duty-card", 1
    hendra.assert_select ".duty-card", 1
    rina.assert_select ".duty-card__title", /VIII A · Matematika/ # jam ke-2: tanpa kit
    rina.assert_select ".duty-card .badge--warn", /Mode cadangan/
    hendra.assert_select ".duty-card__title", /VII A · Matematika/
    hendra.assert_select ".duty-card__kit", /Latihan Pecahan/
    hendra.assert_select ".duty-card__meta", /Menggantikan Sari Wulandari \(Sakit\)/
  end

  test "halaman guru piket berlangganan stream bertanda tangan miliknya sendiri" do
    rina = login_session(:guru_piket)
    rina.get duty_root_path
    signed = rina.css_select("turbo-cable-stream-source").first["signed-stream-name"]
    assert_equal "duty_#{users(:guru_piket).id}", Turbo.signed_stream_verifier.verified(signed)
  end

  test "dashboard wakil kurikulum berlangganan stream sekolahnya" do
    @wakur.get curriculum_root_path
    signed = @wakur.css_select("turbo-cable-stream-source").first["signed-stream-name"]
    assert_equal "curriculum_#{schools(:smp).id}", Turbo.signed_stream_verifier.verified(signed)
  end

  # --- detail untuk guru piket ---
  test "detail kit untuk guru piket: petunjuk, kunci jawaban, unduh PDF" do
    kits(:mtk_7a_siap).worksheet.attach(io: File.open(file_fixture("lembar-kerja.pdf")), filename: "lembar-kerja.pdf", content_type: "application/pdf")
    activate
    hendra = login_session(:guru_piket_dua)
    activation = Activation.find_by(lesson: lessons(:senin_jam1_7a))
    hendra.get duty_activation_path(activation)
    assert_equal 200, hendra.response.status
    hendra.assert_select "h1", "VII A · Matematika"
    hendra.assert_select ".kit-detail", /Bagikan lembar soal/
    hendra.assert_select "details.answer-key", /3\/4/
    hendra.get worksheet_duty_activation_path(activation)
    assert_equal 200, hendra.response.status
    assert hendra.response.body.start_with?("%PDF-")
    assert_match(/attachment/, hendra.response.headers["Content-Disposition"])
  end

  test "mode cadangan: tampil langkah tugas mandiri umum, bukan galat" do
    activate
    rina = login_session(:guru_piket)
    rina.get duty_activation_path(Activation.find_by(lesson: lessons(:senin_jam2_8a)))
    assert_equal 200, rina.response.status
    rina.assert_select ".card__title", /Mode cadangan/
    rina.assert_select "ol.steps li", 4
    rina.get worksheet_duty_activation_path(Activation.find_by(lesson: lessons(:senin_jam2_8a)))
    assert_equal 404, rina.response.status
  end

  test "guru piket lain tidak bisa membuka aktivasi yang bukan miliknya" do
    activate
    rina = login_session(:guru_piket)
    hendras = Activation.find_by(lesson: lessons(:senin_jam1_7a))
    assert_equal users(:guru_piket_dua), hendras.invigilator
    rina.get duty_activation_path(hendras)
    assert_equal 404, rina.response.status
    rina.get worksheet_duty_activation_path(hendras)
    assert_equal 404, rina.response.status
  end

  # --- kegagalan ---
  test "aktivasi gagal: pesan galat dan kembali ke formulir, tanpa data" do
    [ { date: "2026-11-08" }, { date: "2026-11-30" }, { date: "2026-11-14" }, { date: "" }, { teacher_id: "" }, { teacher_id: users(:guru_lain).id },
      { teacher_id: users(:guru_piket).id }, { reason: "malas" } ].each do |overrides|
      assert_no_difference [ "Absence.count", "Activation.count" ] do
        activate(@wakur, overrides)
      end
      @wakur.assert_redirected_to(%r{/curriculum/absences/new})
      @wakur.follow_redirect!
      @wakur.assert_select ".alert--danger", minimum: 1
    end
  end

  # --- hak akses ---
  test "peran selain wakil kurikulum tidak bisa mengaktifkan" do
    %i[guru_mapel guru_piket kepala_sekolah].each do |role|
      session = login_session(role)
      assert_no_difference [ "Absence.count", "Activation.count" ] do
        activate(session)
      end
      assert_equal 403, session.response.status, role
      session.get new_curriculum_absence_path
      assert_equal 403, session.response.status, role
    end
  end

  test "peran lain tidak bisa membuka halaman guru piket" do
    activate
    %i[guru_mapel wakil_kurikulum kepala_sekolah].each do |role|
      session = login_session(role)
      session.get duty_root_path
      assert_equal 403, session.response.status, role
      session.get duty_activation_path(Activation.first)
      assert_equal 403, session.response.status, role
    end
  end

  # --- penugasan piket menyusul ---
  test "tanpa guru piket: aktivasi menunggu, lalu langsung diberikan saat piket ditugaskan" do
    DutyAssignment.delete_all
    activate
    assert Activation.all.all? { |a| a.status == :menunggu_piket }
    @wakur.get curriculum_root_path
    @wakur.assert_select ".alert--warn", /2 kelas perlu perhatian/
    @wakur.assert_select ".badge--warn", text: "Belum ada", minimum: 1
    @wakur.assert_select ".badge--status-warn", text: "Menunggu piket", minimum: 1

    assert_list_broadcasts("duty_#{users(:guru_piket).id}", count: 1) do
      @wakur.post curriculum_duty_assignments_path, params: { duty_assignment: { user_id: users(:guru_piket).id, date: MONDAY.iso8601 } }
    end
    assert Activation.all.all? { |a| a.reload.invigilator == users(:guru_piket) && a.status == :aktif }
    rina = login_session(:guru_piket)
    rina.get duty_root_path
    rina.assert_select ".duty-card", 2
  end

  test "penugasan piket yang sudah menerima kit aktif tidak bisa dihapus" do
    activate
    assignment = DutyAssignment.find_by(user: users(:guru_piket), date: MONDAY)
    assert_no_difference "DutyAssignment.count" do
      @wakur.delete curriculum_duty_assignment_path(assignment)
    end
    @wakur.follow_redirect!
    @wakur.assert_select ".alert--danger", /sudah menerima kit aktif/
  end

  # --- performa ---
  test "halaman daftar tidak N+1: jumlah query tetap saat aktivasi bertambah" do
    activate
    rina = login_session(:guru_piket)
    @wakur.get curriculum_root_path # pemanasan: request pertama memuat metadata
    rina.get duty_root_path
    before_wakur = count_queries { @wakur.get curriculum_root_path }
    before_duty = count_queries { rina.get duty_root_path }

    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY + 1) # Selasa
    Activations::Create.call(actor: users(:wakil_kurikulum), teacher: users(:guru_mapel_dua), date: MONDAY, reason: "izin", today: MONDAY)
    Activations::Create.call(actor: users(:wakil_kurikulum), teacher: users(:guru_mapel_dua), date: MONDAY + 1, reason: "izin", today: MONDAY)

    assert_equal before_wakur, count_queries { @wakur.get curriculum_root_path }
    assert_equal before_duty, count_queries { rina.get duty_root_path }
  end
end
