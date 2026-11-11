# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class KitsTest < ActionDispatch::IntegrationTest
  setup { log_in_as :guru_mapel }

  def assignment(subject, klass) = "#{subjects(subject).id}:#{school_classes(klass).id}"

  def valid_params(overrides = {})
    { assignment: assignment(:matematika, :kelas_8a), title: "Kit Aljabar", duration_minutes: 35,
      supervisor_instructions: "Awasi dan kumpulkan.", answer_key: "1) 2x" }.merge(overrides)
  end

  # --- daftar / bank ---
  test "bank hanya menampilkan kit milik sendiri" do
    get kits_path
    assert_response :success
    assert_select ".kit-card__title a", "Latihan Pecahan"
    assert_select ".kit-card__title a", text: "Ringkasan Sistem Pencernaan", count: 0 # milik guru_mapel_dua
    assert_select ".stat .card__stat", "1" # satu kit siap dipakai
  end

  test "filter mapel, kelas, dan fase" do
    get kits_path(school_class_id: school_classes(:kelas_7a).id, subject_id: subjects(:matematika).id, phase: "D")
    assert_select ".kit-card", 2
    get kits_path(phase: "A")
    assert_select ".kit-card", 0
    assert_select ".empty-state__title", "Tidak ada kit yang cocok"
  end

  test "kelas yang belum punya kit disarankan dengan tautan siap pakai" do
    get kits_path
    assert_select "#missing-title", /Belum punya kit/
    assert_select "a.chip--link[href*='assignment=#{CGI.escape(assignment(:matematika, :kelas_8a))}']", /VIII A · Matematika/
  end

  test "tanpa kit sama sekali menampilkan keadaan kosong yang ramah" do
    Kit.where(user: users(:guru_mapel)).destroy_all
    get kits_path
    assert_select ".empty-state__title", "Belum ada kit"
  end

  # --- templat dan alur cepat ---
  test "formulir baru terisi dari templat" do
    get new_kit_path(template: "baca_rangkum", assignment: assignment(:matematika, :kelas_8a))
    assert_response :success
    assert_select "input[name='kit[title]'][value='Membaca dan Merangkum']"
    assert_select "textarea[name='kit[supervisor_instructions]']", /35 menit/
    assert_select "select[name='kit[assignment]'] option[selected][value='#{assignment(:matematika, :kelas_8a)}']"
    assert_select ".template[aria-current='true']", /Membaca dan merangkum/
  end

  test "tombol Kit baru tanpa parameter apa pun tampil normal" do
    get new_kit_path
    assert_response :success
    assert_select "select[name='kit[assignment]']"
    assert_select ".template", 3
  end

  test "parameter assignment rusak tidak menyebabkan galat" do
    [ "abc", ":", "1:", ":2", "-1:-1", "1:2:3" ].each do |bad|
      get new_kit_path(assignment: bad)
      assert_response :success, bad.inspect
    end
  end

  test "templat tidak dikenal diabaikan tanpa galat" do
    get new_kit_path(template: "ngawur")
    assert_response :success
    assert_select "input[name='kit[duration_minutes]'][value='35']"
  end

  test "alur cepat: saran kosong -> formulir terisi templat -> simpan (3 langkah, tanpa mengetik isi)" do
    get kits_path
    path = css_select("a.chip--link").first["href"]
    get path
    assert_response :success
    title = css_select("input[name='kit[title]']").first["value"]
    instructions = css_select("textarea[name='kit[supervisor_instructions]']").first.text.strip
    value = css_select("select[name='kit[assignment]'] option[selected]").first["value"]
    assert_difference "Kit.count", 1 do
      post kits_path, params: { kit: { assignment: value, title: title, duration_minutes: 35, supervisor_instructions: instructions } }
    end
    kit = Kit.order(:created_at).last
    assert_redirected_to kit_path(kit)
    assert_equal users(:guru_mapel), kit.user
    assert kit.disiapkan?
  end

  # --- buat ---
  test "buat kit valid: pemilik, fase, dan status ditetapkan server" do
    assert_difference "Kit.count", 1 do
      post kits_path, params: { kit: valid_params }
    end
    kit = Kit.order(:created_at).last
    assert_equal users(:guru_mapel), kit.user
    assert_equal "D", kit.phase
    assert_equal school_classes(:kelas_8a), kit.school_class
    assert kit.disiapkan?
    follow_redirect!
    assert_select ".alert--ok", "Kit berhasil disiapkan."
  end

  test "parameter terlarang (user_id, status, times_used) diabaikan" do
    post kits_path, params: { kit: valid_params.merge(user_id: users(:guru_mapel_dua).id, status: "terpakai", times_used: 99, phase: "A") }
    kit = Kit.order(:created_at).last
    assert_equal users(:guru_mapel), kit.user
    assert kit.disiapkan?
    assert_equal 0, kit.times_used
    assert_equal "D", kit.phase
  end

  test "buat untuk kelas/mapel yang tidak diajar ditolak" do
    assert_no_difference "Kit.count" do
      post kits_path, params: { kit: valid_params(assignment: assignment(:ipa, :kelas_8a)) } # guru_mapel tidak mengajar IPA
    end
    assert_response :unprocessable_entity
    assert_select ".alert--danger li", /tidak mengajar/
  end

  test "buat dengan pasangan dari sekolah lain ditolak" do
    assert_no_difference "Kit.count" do
      post kits_path, params: { kit: valid_params(assignment: assignment(:mapel_lain, :kelas_lain)) }
    end
    assert_response :unprocessable_entity
  end

  test "judul, petunjuk, dan durasi divalidasi dengan pesan Indonesia" do
    post kits_path, params: { kit: valid_params(title: "", supervisor_instructions: "", duration_minutes: 90) }
    assert_response :unprocessable_entity
    assert_select ".alert--danger li", /Judul/
    assert_select ".alert--danger li", /Petunjuk untuk pengawas/
    assert_select ".alert--danger li", /Durasi/
  end

  test "isian tetap terjaga saat galat" do
    post kits_path, params: { kit: valid_params(title: "", answer_key: "kunci saya") }
    assert_select "textarea[name='kit[answer_key]']", /kunci saya/
  end

  # --- PDF ---
  test "unggah PDF asli" do
    assert_difference "Kit.count", 1 do
      post kits_path, params: { kit: valid_params(worksheet: fixture_file_upload("lembar-kerja.pdf", "application/pdf")) }
    end
    kit = Kit.order(:created_at).last
    assert kit.worksheet.attached?
    follow_redirect!
    assert_select "a[href='#{worksheet_kit_path(kit)}']", /lembar-kerja\.pdf/
  end

  test "unggah teks palsu yang mengaku PDF ditolak" do
    assert_no_difference [ "Kit.count", "ActiveStorage::Blob.count" ] do
      post kits_path, params: { kit: valid_params(worksheet: fixture_file_upload("palsu.pdf", "application/pdf")) }
    end
    assert_response :unprocessable_entity
    assert_select ".alert--danger li", /Lampiran PDF/
  end

  test "unduh lampiran: pemilik berhasil, sebagai attachment dengan nosniff" do
    kit = kits(:mtk_7a_siap)
    kit.worksheet.attach(io: File.open(file_fixture("lembar-kerja.pdf")), filename: "lembar-kerja.pdf", content_type: "application/pdf")
    get worksheet_kit_path(kit)
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_match(/attachment/, response.headers["Content-Disposition"])
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert response.body.start_with?("%PDF-")
  end

  test "unduh tanpa lampiran 404, kit guru lain 404" do
    get worksheet_kit_path(kits(:mtk_7a_siap))
    assert_response :not_found
    get worksheet_kit_path(kits(:ipa_7a_siap))
    assert_response :not_found
  end

  test "ubah dengan menghapus lampiran" do
    kit = kits(:mtk_7a_siap)
    kit.worksheet.attach(io: File.open(file_fixture("lembar-kerja.pdf")), filename: "lembar-kerja.pdf", content_type: "application/pdf")
    patch kit_path(kit), params: { kit: valid_params(assignment: assignment(:matematika, :kelas_7a)).merge(remove_worksheet: "1") }
    assert_redirected_to kit_path(kit)
    assert_not kit.reload.worksheet.attached?
  end

  # --- lihat / ubah / hapus ---
  test "detail menampilkan petunjuk dan kunci jawaban" do
    get kit_path(kits(:mtk_7a_siap))
    assert_response :success
    assert_select "h1", "Latihan Pecahan"
    assert_select ".kit-detail", /Bagikan lembar soal/
    assert_select ".kit-detail", /3\/4/
  end

  test "ubah kit" do
    kit = kits(:mtk_7a_siap)
    patch kit_path(kit), params: { kit: valid_params(assignment: assignment(:matematika, :kelas_7a), title: "Judul Baru") }
    assert_redirected_to kit_path(kit)
    assert_equal "Judul Baru", kit.reload.title
  end

  test "kit aktif tidak bisa diubah atau dihapus" do
    kit = kits(:mtk_7a_siap)
    kit.activate!
    get edit_kit_path(kit)
    assert_redirected_to kit_path(kit)
    patch kit_path(kit), params: { kit: valid_params(title: "Diubah") }
    assert_redirected_to kit_path(kit)
    assert_no_difference "Kit.count" do
      delete kit_path(kit)
    end
    assert_not_equal "Diubah", kit.reload.title
  end

  test "hapus kit yang belum pernah dipakai" do
    assert_difference "Kit.count", -1 do
      delete kit_path(kits(:mtk_7a_siap))
    end
    assert_redirected_to kits_path
  end

  test "kit yang pernah punya aktivasi tidak bisa dihapus" do
    kit = kits(:mtk_7a_terpakai)
    absence = Absence.create!(teacher: users(:guru_mapel), date: Date.new(2026, 11, 9), reason: "sakit", created_by: users(:wakil_kurikulum))
    Activation.create!(absence: absence, lesson: lessons(:senin_jam1_7a), kit: kit, invigilator: users(:guru_piket), activated_at: 2.hours.ago, completed_at: 1.hour.ago)
    assert_no_difference "Kit.count" do
      delete kit_path(kit)
    end
    follow_redirect!
    assert_select ".alert--danger", /tidak bisa dihapus/
  end

  test "duplikat membuat salinan siap pakai tanpa menyalin riwayat" do
    kit = kits(:mtk_7a_terpakai)
    assert_difference "Kit.count", 1 do
      post duplicate_kit_path(kit)
    end
    copy = Kit.order(:created_at).last
    assert_redirected_to edit_kit_path(copy)
    assert_equal "Latihan Bilangan Bulat (salinan)", copy.title
    assert copy.disiapkan?
    assert_equal 0, copy.times_used
    assert_nil copy.last_used_at
  end

  test "duplikat menyalin lampiran tanpa memutuskan lampiran asli" do
    kit = kits(:mtk_7a_siap)
    kit.worksheet.attach(io: File.open(file_fixture("lembar-kerja.pdf")), filename: "lembar-kerja.pdf", content_type: "application/pdf")
    post duplicate_kit_path(kit)
    copy = Kit.order(:created_at).last
    assert copy.worksheet.attached?
    copy.destroy
    assert kit.reload.worksheet.attached?
    assert_equal "%PDF-", kit.worksheet.download[0, 5]
  end

  # --- isolasi antar guru ---
  test "kit guru lain tidak bisa dilihat, diubah, dihapus, atau diduplikat" do
    other = kits(:ipa_7a_siap)
    get kit_path(other)
    assert_response :not_found
    get edit_kit_path(other)
    assert_response :not_found
    patch kit_path(other), params: { kit: { title: "Diretas" } }
    assert_response :not_found
    delete kit_path(other)
    assert_response :not_found
    post duplicate_kit_path(other)
    assert_response :not_found
    assert_equal "Ringkasan Sistem Pencernaan", other.reload.title
  end

  test "ID ngawur 404, bukan 500" do
    get kit_path(0)
    assert_response :not_found
  end

  test "pemilik dipertahankan saat diubah walau dikirim user_id lain" do
    kit = kits(:mtk_7a_siap)
    patch kit_path(kit), params: { kit: valid_params(assignment: assignment(:matematika, :kelas_7a)).merge(user_id: users(:guru_mapel_dua).id) }
    assert_equal users(:guru_mapel), kit.reload.user
  end
end
