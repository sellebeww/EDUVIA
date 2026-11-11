# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class Activations::CreateTest < ActiveSupport::TestCase
  MONDAY = Date.new(2026, 11, 9)

  setup do
    travel_to Time.zone.local(2026, 11, 9, 7, 0) # Senin; siaran memakai Date.current
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY)
    DutyAssignment.create!(user: users(:guru_piket_dua), date: MONDAY)
  end

  def run_create(overrides = {})
    Activations::Create.call(**{ actor: users(:wakil_kurikulum), teacher: users(:guru_mapel), date: MONDAY, reason: "sakit", today: MONDAY }.merge(overrides))
  end

  # --- jalur utama ---
  test "mengaktifkan semua jam mengajar: kit cocok, kit jadi aktif, lembar terisi" do
    result = nil
    assert_difference [ "Absence.count" ], 1 do
      assert_difference "Activation.count", 2 do
        result = run_create
      end
    end
    assert result.ok?, result.error
    assert_equal 2, result.created.size
    seven = Activation.find_by(lesson: lessons(:senin_jam1_7a))
    assert_equal kits(:mtk_7a_siap), seven.kit
    assert kits(:mtk_7a_siap).reload.aktif?
    assert_equal 3, seven.attendance_records.count, "3 siswa kelas 7A"
    assert_equal 3, seven.submissions.count
    assert seven.attendance_records.all?(&:hadir?)
    assert seven.submissions.none?(&:submitted?)
    assert_equal :aktif, seven.status
    assert_not seven.reused
  end

  test "kelas tanpa kit tetap tercatat dengan mode cadangan dan peringatan, tanpa galat" do
    result = run_create
    eight = Activation.find_by(lesson: lessons(:senin_jam2_8a))
    assert_nil eight.kit
    assert_includes eight.warning_codes, "no_kit"
    assert result.warnings.any? { |w| w.include?("VIII A") && w.include?("mode cadangan") }
    assert_equal 1, eight.attendance_records.count
  end

  test "dua jam pada hari berbeda dibagi ke dua guru piket" do
    run_create
    invigilators = Activation.all.map(&:invigilator)
    assert_equal 2, invigilators.uniq.size
  end

  test "alasan dan pembuat tersimpan di Absence" do
    run_create(reason: "dinas", note: "Rapat dinas")
    absence = Absence.find_by!(teacher: users(:guru_mapel), date: MONDAY)
    assert_equal "dinas", absence.reason
    assert_equal "Rapat dinas", absence.note
    assert_equal users(:wakil_kurikulum), absence.created_by
  end

  # --- idempotensi ---
  test "memanggil dua kali: hasil sama, tanpa data ganda, kit tidak berubah lagi" do
    run_create
    result = nil
    assert_no_difference [ "Absence.count", "Activation.count", "AttendanceRecord.count", "Submission.count" ] do
      result = run_create(reason: "izin")
    end
    assert result.ok?
    assert_empty result.created
    assert_equal 2, result.existing.size
    assert_includes result.message, "sudah diaktifkan sebelumnya"
    assert_equal "sakit", Absence.find_by!(teacher: users(:guru_mapel), date: MONDAY).reason, "alasan awal tidak ditimpa"
    assert_equal 1, kits(:mtk_7a_siap).reload.times_used + (kits(:mtk_7a_siap).aktif? ? 1 : 0)
  end

  test "siaran hanya terjadi pada aktivasi pertama" do
    piket_streams = [ users(:guru_piket), users(:guru_piket_dua) ].map { |u| "duty_#{u.id}" }
    assert_list_broadcasts(piket_streams.first, count: 1) do
      assert_list_broadcasts(piket_streams.last, count: 1) do
        assert_list_broadcasts("curriculum_#{schools(:smp).id}", count: 1) { run_create }
      end
    end
    assert_list_broadcasts(piket_streams.first, count: 0) { run_create }
    assert_list_broadcasts("curriculum_#{schools(:smp).id}", count: 0) { run_create }
  end

  test "kartu yang disiarkan memuat kelas dan kit" do
    streams = capture_turbo_stream_broadcasts("duty_#{users(:guru_piket_dua).id}") { run_create }
    html = streams.first.to_html
    assert_equal "replace", streams.first["action"]
    assert_equal "duty-activations", streams.first["target"]
    assert_match(/VII A|VIII A/, html)
  end

  test "guru piket menerima toast 'Kit baru masuk' yang meringkas kelasnya, hanya pada aktivasi pertama" do
    DutyAssignment.where(user: users(:guru_piket_dua)).delete_all
    toasts = captured_toasts("duty_#{users(:guru_piket).id}") { run_create }
    assert_equal 1, toasts.size, "satu toast per guru piket, walau ada beberapa kelas"
    html = toasts.first.to_html
    assert_includes html, "Kit baru masuk"
    assert_includes html, "dan 1 kelas lain"
    assert_empty captured_toasts("duty_#{users(:guru_piket).id}") { run_create }
  end

  # --- kasus tepi ---
  test "tanpa guru piket: aktivasi menunggu, dengan peringatan, hanya dashboard wakur yang diperbarui" do
    DutyAssignment.delete_all
    result = nil
    assert_list_broadcasts("duty_#{users(:guru_piket).id}", count: 0) do
      assert_list_broadcasts("curriculum_#{schools(:smp).id}", count: 1) { result = run_create }
    end
    assert result.ok?
    activations = Activation.all
    assert activations.all? { |a| a.invigilator.nil? && a.warning_codes.include?("no_invigilator") }
    assert activations.all? { |a| a.status == :menunggu_piket }
    assert result.warnings.any? { |w| w.include?("Belum ada guru piket") }
  end

  test "dua guru berhalangan, jam yang sama, dua guru piket: dibagi tanpa bentrok" do
    run_create(teacher: users(:guru_mapel))
    result = run_create(teacher: users(:guru_mapel_dua))
    seven_ipa = Activation.find_by(lesson: lessons(:senin_jam2_7a))
    eight_mtk = Activation.find_by(lesson: lessons(:senin_jam2_8a))
    assert_not_equal seven_ipa.invigilator, eight_mtk.invigilator
    assert_not_includes seven_ipa.warning_codes, "concurrent_conflict"
    assert result.ok?
  end

  test "dua guru berhalangan, jam yang sama, satu guru piket: tetap ditugaskan dengan peringatan bentrok" do
    DutyAssignment.where(user: users(:guru_piket_dua)).delete_all
    run_create(teacher: users(:guru_mapel))
    result = run_create(teacher: users(:guru_mapel_dua))
    seven_ipa = Activation.find_by(lesson: lessons(:senin_jam2_7a))
    assert_equal users(:guru_piket), seven_ipa.invigilator
    assert_includes seven_ipa.warning_codes, "concurrent_conflict"
    assert result.warnings.any? { |w| w.include?("kelas lain pada jam yang sama") }
  end

  test "kit terpakai dipakai ulang dengan penanda" do
    kits(:mtk_7a_siap).destroy
    run_create
    activation = Activation.find_by(lesson: lessons(:senin_jam1_7a))
    assert_equal kits(:mtk_7a_terpakai), activation.kit
    assert activation.reused
    assert kits(:mtk_7a_terpakai).reload.aktif?
  end

  test "jam ganda mapel yang sama: kit kedua dipakai ulang, lalu mode cadangan bila kit habis" do
    [ [ 4, "09:00", "09:40" ], [ 5, "09:40", "10:20" ] ].each do |number, from, to|
      period = Period.create!(school: schools(:smp), number: number, starts_at: from, ends_at: to)
      Lesson.create!(school_class: school_classes(:kelas_7a), subject: subjects(:matematika), teacher: users(:guru_mapel), period: period, day_of_week: 1)
    end
    run_create
    used = Activation.joins(lesson: :period)
                     .where(lessons: { school_class_id: school_classes(:kelas_7a).id, subject_id: subjects(:matematika).id })
                     .order("periods.number").map(&:kit)
    assert_equal [ kits(:mtk_7a_siap), kits(:mtk_7a_terpakai), nil ], used
    assert_equal [ false, true, false ], Activation.joins(lesson: :period).where(lessons: { school_class_id: school_classes(:kelas_7a).id, subject_id: subjects(:matematika).id }).order("periods.number").map(&:reused)
  end

  test "guru tanpa jam mengajar pada hari itu: sukses tanpa membuat apa pun" do
    result = nil
    assert_no_difference [ "Absence.count", "Activation.count" ] do
      result = run_create(date: MONDAY + 2, today: MONDAY + 2) # Rabu
    end
    assert result.ok?
    assert_includes result.message, "tidak mengajar"
  end

  # --- validasi ---
  test "ditolak: tanggal lewat, terlalu jauh, bukan hari aktif" do
    { MONDAY - 1 => "sudah lewat", MONDAY + 8 => "terlalu jauh", MONDAY + 5 => "bukan hari aktif" }.each do |date, text|
      assert_no_difference [ "Absence.count", "Activation.count" ] do
        result = run_create(date: date)
        assert_not result.ok?
        assert_includes result.error, text
      end
    end
  end

  test "tanggal batas 7 hari ke depan diterima" do
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY + 7)
    assert run_create(date: MONDAY + 7).ok? # Senin berikutnya
  end

  test "ditolak: bukan wakil kurikulum, bukan guru_mapel, guru sekolah lain, tanggal/guru kosong" do
    [ { actor: users(:guru_piket) }, { actor: users(:kepala_sekolah) }, { actor: nil },
      { teacher: users(:guru_piket) }, { teacher: users(:guru_lain) }, { teacher: nil }, { date: nil } ].each do |overrides|
      assert_no_difference [ "Absence.count", "Activation.count" ] do
        assert_not run_create(overrides).ok?, overrides.inspect
      end
    end
  end

  test "ditolak: alasan tidak valid dan tidak meninggalkan data setengah jadi" do
    assert_no_difference [ "Absence.count", "Activation.count" ] do
      result = run_create(reason: "malas")
      assert_not result.ok?
    end
    assert kits(:mtk_7a_siap).reload.disiapkan?
  end

  # --- ketahanan ---
  test "galat di tengah proses membatalkan semuanya (transaksi)" do
    calls = 0
    original = Activation.method(:create!)
    result = nil
    stub_method(Activation, :create!, ->(**attrs) { (calls += 1) == 2 ? raise(ActiveRecord::RecordNotUnique, "bentrok") : original.call(**attrs) }) do
      assert_no_difference [ "Absence.count", "Activation.count", "AttendanceRecord.count" ] do
        result = run_create
      end
    end
    assert_not result.ok?
    assert_includes result.error, "coba lagi"
    assert kits(:mtk_7a_siap).reload.disiapkan?, "kit tidak boleh tertinggal berstatus aktif"
  end

  test "kegagalan siaran tidak membatalkan aktivasi yang sudah tersimpan" do
    result = nil
    stub_method(Turbo::StreamsChannel, :broadcast_replace_to, ->(*, **) { raise "kabel putus" }) do
      assert_difference "Activation.count", 2 do
        result = run_create
      end
    end
    assert result.ok?
  end

  test "pesan ringkasan menyebut jumlah kelas, guru, dan tanggal" do
    result = run_create
    assert_includes result.message, "2 kelas diaktifkan"
    assert_includes result.message, "Sari Wulandari"
    assert_includes result.message, "Senin, 09 November 2026"
  end
end
