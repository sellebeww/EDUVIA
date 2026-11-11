# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class KitTest < ActiveSupport::TestCase
  def build(attrs = {})
    Kit.new({ user: users(:guru_mapel), subject: subjects(:matematika), school_class: school_classes(:kelas_8a),
              title: "Kit Baru", duration_minutes: 35, supervisor_instructions: "Awasi dan kumpulkan." }.merge(attrs))
  end

  # --- validasi ---
  test "valid, status awal disiapkan, fase diturunkan dari kelas" do
    kit = build
    assert kit.valid?, kit.errors.full_messages.to_s
    assert kit.disiapkan?
    assert_equal "D", kit.phase
    kit.school_class = school_classes(:kelas_7a)
    kit.valid?
    assert_equal "D", kit.phase
  end

  test "judul dan petunjuk pengawas wajib" do
    assert_not build(title: " ").valid?
    assert_not build(supervisor_instructions: "").valid?
  end

  test "durasi harus 30 sampai 40 menit" do
    [ 29, 41, nil ].each { |d| assert_not build(duration_minutes: d).valid?, d.inspect }
    [ 30, 35, 40 ].each { |d| assert build(duration_minutes: d).valid?, d.to_s }
  end

  test "pemilik harus guru_mapel" do
    assert_not build(user: users(:guru_piket)).valid?
  end

  test "pemilik harus mengajar mapel itu di kelas itu" do
    kit = build(subject: subjects(:ipa)) # guru_mapel tidak mengajar IPA
    assert_not kit.valid?
    assert_includes kit.errors[:base].join, "tidak mengajar"
  end

  test "status di luar daftar ditolak" do
    assert_not build(status: "rahasia").valid?
  end

  test "batas durasi dan status juga dijaga database" do
    kit = build(duration_minutes: 99)
    kit.valid?
    assert_raises(ActiveRecord::StatementInvalid) { kit.save!(validate: false) }
  end

  test "scope filter mapel, kelas, fase" do
    assert_equal 2, Kit.by_subject(subjects(:matematika).id).count
    assert_equal 3, Kit.by_class(school_classes(:kelas_7a).id).count
    assert_equal 3, Kit.by_phase("D").count
    assert_equal 0, Kit.by_phase("A").count
    assert_equal Kit.count, Kit.by_subject(nil).by_class("").by_phase(nil).count
  end

  # --- lampiran PDF ---
  def attach_file(kit, fixture, content_type: "application/pdf", filename: nil)
    kit.worksheet.attach(io: File.open(file_fixture(fixture)), filename: filename || fixture, content_type: content_type)
  end

  test "tanpa lampiran tetap valid" do
    assert build.valid?
  end

  test "PDF asli diterima" do
    kit = build
    attach_file(kit, "lembar-kerja.pdf")
    assert kit.valid?, kit.errors.full_messages.to_s
    assert kit.save
    assert kit.worksheet.attached?
  end

  test "teks yang dinamai .pdf dan mengaku application/pdf ditolak (cek isi berkas)" do
    kit = build
    attach_file(kit, "palsu.pdf")
    assert_not kit.valid?
    assert_includes kit.errors[:worksheet].join, "PDF"
  end

  test "berkas bukan PDF ditolak walau ekstensi .pdf" do
    kit = build
    kit.worksheet.attach(io: StringIO.new("\x89PNG\r\n\x1a\n" + "x" * 50), filename: "gambar.pdf", content_type: "image/png")
    assert_not kit.valid?
  end

  test "PDF lebih dari 5 MB ditolak" do
    kit = build
    big = "%PDF-1.4\n" + ("a" * (5.megabytes + 1))
    kit.worksheet.attach(io: StringIO.new(big), filename: "besar.pdf", content_type: "application/pdf")
    assert_not kit.valid?
    assert_includes kit.errors[:worksheet].join, "5 MB"
  end

  test "PDF tepat 5 MB diterima" do
    kit = build
    exact = "%PDF-1.4\n" + ("a" * (5.megabytes - 9))
    kit.worksheet.attach(io: StringIO.new(exact), filename: "pas.pdf", content_type: "application/pdf")
    assert kit.valid?, kit.errors.full_messages.to_s
  end

  test "kit lama dengan lampiran tetap bisa diubah tanpa divalidasi ulang" do
    kit = build
    attach_file(kit, "lembar-kerja.pdf")
    kit.save!
    kit = Kit.find(kit.id)
    assert kit.update(title: "Judul baru")
  end

  test "editable hanya bila tidak aktif" do
    assert kits(:mtk_7a_siap).editable?
    assert kits(:mtk_7a_terpakai).editable?
    assert_not kits(:mtk_7a_siap).tap(&:activate!).editable?
  end

  # --- transisi status ---
  VALID = { activate!: %w[disiapkan aktif], complete!: %w[aktif terpakai], reuse!: %w[terpakai aktif] }.freeze

  test "disiapkan -> aktif" do
    kit = kits(:mtk_7a_siap).activate!
    assert kit.reload.aktif?
  end

  test "aktif -> terpakai menambah penghitung dan mencatat waktu" do
    kit = kits(:mtk_7a_siap)
    kit.activate!
    assert_difference -> { kit.reload.times_used }, 1 do
      kit.complete!
    end
    assert kit.terpakai?
    assert_in_delta Time.current.to_f, kit.last_used_at.to_f, 5
  end

  test "terpakai -> aktif (pakai ulang) tidak mengubah penghitung sampai selesai lagi" do
    kit = kits(:mtk_7a_terpakai)
    assert_no_difference -> { kit.reload.times_used } do
      kit.reuse!
    end
    assert kit.aktif?
    kit.complete!
    assert_equal 2, kit.reload.times_used
  end

  VALID.each do |method, (from, to)|
    %w[disiapkan aktif terpakai].each do |state|
      if state == from
        test "#{method} dari #{state} berhasil menjadi #{to}" do
          kit = kits(:mtk_7a_siap)
          kit.update_columns(status: state)
          kit.public_send(method)
          assert_equal to, kit.reload.status
        end
      else
        test "#{method} dari #{state} ditolak dan status tidak berubah" do
          kit = kits(:mtk_7a_siap)
          kit.update_columns(status: state, times_used: 0)
          assert_raises(Kit::InvalidTransition) { kit.public_send(method) }
          assert_equal state, kit.reload.status
          assert_equal 0, kit.times_used
        end
      end
    end
  end

  test "transisi memakai data terbaru dari database (aman dari objek basi)" do
    stale = Kit.find(kits(:mtk_7a_siap).id)
    Kit.find(stale.id).activate!
    assert_raises(Kit::InvalidTransition) { stale.activate! }
  end

  test "label status" do
    assert_equal "Disiapkan", kits(:mtk_7a_siap).status_label
    assert_equal "Terpakai", kits(:mtk_7a_terpakai).status_label
  end
end
