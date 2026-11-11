# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

# Satu alur penuh lintas peran: dari menyiapkan kit sampai laporan kepala sekolah.
class FullFlowTest < ActionDispatch::IntegrationTest
  MONDAY = Date.new(2026, 11, 9)

  test "menyiapkan kit -> aktivasi -> piket mengisi dan menyelesaikan -> hasil guru -> laporan kepala sekolah" do
    travel_to Time.zone.local(2026, 11, 9, 7, 0)
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY)

    # 1. Guru mapel menyiapkan kit untuk VIII A (kelas yang belum punya kit) lewat templat.
    sari = login_session(:guru_mapel)
    sari.get sari.kits_path
    suggestion = sari.css_select("a.chip--link").map { |a| a["href"] }.find { |h| h.include?(CGI.escape("#{subjects(:matematika).id}:#{school_classes(:kelas_8a).id}")) }
    assert suggestion, "VIII A · Matematika harus disarankan"
    sari.get suggestion
    title = sari.css_select("input[name='kit[title]']").first["value"]
    instructions = sari.css_select("textarea[name='kit[supervisor_instructions]']").first.text.strip
    sari.post sari.kits_path, params: { kit: { assignment: "#{subjects(:matematika).id}:#{school_classes(:kelas_8a).id}", title: title, duration_minutes: 35, supervisor_instructions: instructions } }
    kit = Kit.find_by!(user: users(:guru_mapel), school_class: school_classes(:kelas_8a), subject: subjects(:matematika))
    assert kit.disiapkan?

    # 2. Wakil kurikulum menandai Sari berhalangan dan menekan satu tombol.
    wakur = login_session(:wakil_kurikulum)
    wakur.post wakur.curriculum_absences_path, params: { teacher_id: users(:guru_mapel).id, date: MONDAY.iso8601, reason: "sakit" }
    wakur.assert_redirected_to wakur.curriculum_root_path
    assert_equal 2, Activation.count
    eight = Activation.find_by(lesson: lessons(:senin_jam2_8a))
    assert_equal kit, eight.kit, "kit baru langsung dipakai untuk VIII A"
    assert_not_includes eight.warning_codes, "no_kit"

    # 3. Guru piket membuka, mengisi lembar, dan menyelesaikan jam VIII A.
    rina = login_session(:guru_piket)
    rina.get rina.duty_root_path
    rina.assert_select ".duty-card", 2
    rina.get rina.duty_activation_path(eight)
    record = eight.attendance_records.first
    submission = eight.submissions.first
    rina.patch rina.duty_activation_attendance_record_path(eight, record), params: { attendance_record: { status: "hadir" } }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    rina.patch rina.duty_activation_submission_path(eight, submission), params: { submission: { submitted: "1", score: "95", note: "Tuntas" } }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    rina.patch rina.complete_duty_activation_path(eight)
    assert eight.reload.completed?
    assert kit.reload.terpakai?

    # 4. Hasil kembali ke Sari (guru pemilik materi).
    sari.get sari.results_path
    sari.assert_select ".result-card__title", /VIII A · Matematika/
    sari.assert_select ".result-card__stats", /1\/1/
    sari.assert_select ".result-card__stats", /95/
    sari.get sari.kits_path
    sari.assert_select ".stat", /1\s*Sedang dipakai/m   # kit VII A masih aktif
    sari.assert_select ".stat", /2\s*Sudah terpakai/m   # kit lama (fixture) + kit baru VIII A

    # 5. Kepala sekolah melihat laporan bulan ini.
    kepsek = login_session(:kepala_sekolah)
    kepsek.get kepsek.report_path("2026-11")
    kepsek.assert_select ".stat", /2\s*Jam kosong/m
    kepsek.assert_select ".stat", /50%\s*Tertangani kit/m
    kepsek.assert_select ".stat", /1 jam belum diselesaikan/
    kepsek.assert_select ".hbar__label", text: "Sakit"
  end
end
