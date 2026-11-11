# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

# Banyak thread menekan tombol Aktifkan bersamaan untuk guru dan tanggal yang sama.
# Tes ini memakai koneksi nyata (bukan transaksi tes), jadi data dibersihkan sendiri di akhir.
class Activations::ConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  MONDAY = Date.new(2026, 11, 9)

  setup do
    @kits_before = Kit.all.map { |k| [ k.id, k.attributes ] }.to_h
    travel_to Time.zone.local(2026, 11, 9, 7, 0)
    DutyAssignment.create!(user: users(:guru_piket), date: MONDAY)
    DutyAssignment.create!(user: users(:guru_piket_dua), date: MONDAY)
  end

  teardown do
    AttendanceRecord.delete_all
    Submission.delete_all
    Activation.delete_all
    Absence.delete_all
    DutyAssignment.delete_all
    @kits_before.each { |id, attrs| Kit.find(id).update_columns(attrs.except("id")) }
  end

  test "4 thread bersamaan menghasilkan tepat satu rangkaian aktivasi" do
    results = Queue.new
    errors = Queue.new
    # Pool koneksi tes berukuran 5 (termasuk thread utama), jadi 4 thread bersaing tanpa antre koneksi.
    threads = 4.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          results << Activations::Create.call(actor: User.find(users(:wakil_kurikulum).id), teacher: User.find(users(:guru_mapel).id),
                                              date: MONDAY, reason: "sakit", today: MONDAY)
        end
      rescue StandardError => e
        errors << e
      end
    end
    threads.each(&:join)

    assert_equal 0, errors.size, errors.size.positive? ? errors.pop.full_message : ""
    all = Array(results.size.times.map { results.pop })
    assert_equal 4, all.size
    assert all.all?(&:ok?), all.reject(&:ok?).map(&:error).inspect
    assert_equal 1, all.count { |r| r.created.any? }, "hanya satu pemanggilan yang membuat data"
    assert_equal 1, Absence.where(teacher: users(:guru_mapel), date: MONDAY).count
    assert_equal 2, Activation.count
    assert_equal 4, AttendanceRecord.count, "3 siswa 7A + 1 siswa 8A, tanpa duplikat"
    assert_equal 4, Submission.count
    assert Kit.find(kits(:mtk_7a_siap).id).aktif?
    assert_equal 1, Kit.aktif.count
  end

  test "dua guru berbeda bersamaan tidak saling mengganggu" do
    threads = [ users(:guru_mapel), users(:guru_mapel_dua) ].map do |teacher|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Activations::Create.call(actor: User.find(users(:wakil_kurikulum).id), teacher: User.find(teacher.id), date: MONDAY, reason: "sakit", today: MONDAY)
        end
      end
    end
    results = threads.map(&:value)
    assert results.all?(&:ok?), results.reject(&:ok?).map(&:error).inspect
    assert_equal 3, Activation.count # 2 jam guru_mapel + 1 jam guru_mapel_dua
    assert_equal 2, Absence.count
  end
end
