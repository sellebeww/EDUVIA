# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class Activations::CompleteTest < ActiveSupport::TestCase
  MONDAY = Date.new(2026, 11, 9)

  setup do
    travel_to Time.zone.local(2026, 11, 9, 7, 0)
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY)
    DutyAssignment.create!(user: users(:guru_piket_dua), date: MONDAY)
    Activations::Create.call(actor: users(:wakil_kurikulum), teacher: users(:guru_mapel), date: MONDAY, reason: "sakit", today: MONDAY)
    @with_kit = Activation.find_by(lesson: lessons(:senin_jam1_7a))
    @no_kit = Activation.find_by(lesson: lessons(:senin_jam2_8a))
  end

  def complete(activation, actor = activation.invigilator)
    Activations::Complete.call(activation: activation, actor: actor)
  end

  test "menyelesaikan: waktu selesai tercatat, kit menjadi terpakai dan penghitung bertambah" do
    kit = @with_kit.kit
    result = complete(@with_kit)
    assert result.ok?
    assert_not result.already
    assert @with_kit.reload.completed?
    assert_equal :selesai, @with_kit.status
    assert kit.reload.terpakai?
    assert_equal 1, kit.times_used
    assert_in_delta Time.current.to_f, kit.last_used_at.to_f, 5
  end

  test "aktivasi tanpa kit (mode cadangan) tetap bisa diselesaikan" do
    result = complete(@no_kit)
    assert result.ok?
    assert @no_kit.reload.completed?
  end

  test "idempoten: kedua kali tidak mengubah apa pun dan tidak menyiarkan lagi" do
    complete(@with_kit)
    first_time = @with_kit.reload.completed_at
    result = nil
    assert_list_broadcasts("curriculum_#{schools(:smp).id}", count: 0) { result = complete(@with_kit) }
    assert result.ok?
    assert result.already
    assert_equal first_time, @with_kit.reload.completed_at
    assert_equal 1, @with_kit.kit.reload.times_used
  end

  test "hanya guru piket penerima yang boleh menyelesaikan" do
    other = (@with_kit.invigilator == users(:guru_piket) ? users(:guru_piket_dua) : users(:guru_piket))
    [ other, users(:wakil_kurikulum), users(:guru_mapel), users(:kepala_sekolah), nil ].each do |actor|
      result = complete(@with_kit, actor)
      assert_not result.ok?, actor&.role.inspect
    end
    assert_not @with_kit.reload.completed?
    assert @with_kit.kit.aktif?
  end

  test "kit dalam status tidak sesuai: gagal dengan pesan, dan tidak setengah selesai" do
    @with_kit.kit.update_columns(status: "disiapkan")
    result = complete(@with_kit)
    assert_not result.ok?
    assert_includes result.error, "Status kit"
    assert_not @with_kit.reload.completed?, "selesai harus dibatalkan bila kit gagal berpindah status"
  end

  test "siaran ke guru piket, wakil kurikulum, dan guru mapel pemilik materi" do
    piket = "duty_#{@with_kit.invigilator_id}"
    assert_list_broadcasts(piket, count: 1) do
      assert_list_broadcasts("curriculum_#{schools(:smp).id}", count: 1) do
        assert_list_broadcasts("teacher_#{users(:guru_mapel).id}", count: 1) { complete(@with_kit) }
      end
    end
  end

  test "guru mapel menerima toast 'Hasil masuk'" do
    toasts = captured_toasts("teacher_#{users(:guru_mapel).id}") { complete(@with_kit) }
    assert_equal 1, toasts.size
    assert_includes toasts.first.to_html, "Hasil masuk"
    assert_includes toasts.first.to_html, "VII A · Matematika"
  end

  test "siaran ke guru mapel memuat hasil dan hitungan kit" do
    @with_kit.attendance_records.first.update!(status: "tidak_hadir")
    @with_kit.submissions.first.update!(submitted: true, score: 80)
    streams = capture_turbo_stream_broadcasts("teacher_#{users(:guru_mapel).id}") { complete(@with_kit) }
    html = streams.first.to_html
    assert_equal "teacher-live", streams.first["target"]
    assert_includes html, "VII A · Matematika"
    assert_includes html, "2/3"   # hadir
    assert_includes html, "1/3"   # mengumpulkan
    assert_includes html, "80"    # rata-rata
  end
end
