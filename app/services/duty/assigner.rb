# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Duty
  # Memilih guru piket untuk sebuah jam pelajaran pada satu tanggal.
  #   - Utamakan guru piket yang belum menangani kelas lain pada jam yang sama.
  #   - Di antara kandidat, pilih yang beban aktivasi terbukanya paling sedikit.
  #   - Bila semua sedang menangani kelas lain pada jam itu, tetap ditugaskan dengan peringatan.
  #   - Bila tidak ada guru piket bertugas, kembalikan nil dengan peringatan.
  # Objek ini menyimpan keadaan (beban) selama dipakai, jadi satu instans dipakai untuk semua jam dalam satu rencana.
  class Assigner
    Pick = Struct.new(:user, :warning_codes)

    def initialize(date:, school:)
      @duty = User.where(id: DutyAssignment.on(date).select(:user_id), school_id: school.id).order(:name, :id).to_a
      @loads = Hash.new(0)
      @busy = Set.new
      return if @duty.empty?

      Activation.open.joins(:absence, :lesson).where(absences: { date: date }, invigilator_id: @duty.map(&:id))
                .pluck(:invigilator_id, "lessons.period_id").each do |user_id, period_id|
        @loads[user_id] += 1
        @busy << [ user_id, period_id ]
      end
    end

    def assign(period_id)
      return Pick.new(nil, [ "no_invigilator" ]) if @duty.empty?

      free = @duty.reject { |u| @busy.include?([ u.id, period_id ]) }
      user = (free.presence || @duty).min_by { |u| [ @loads[u.id], u.name, u.id ] }
      @loads[user.id] += 1
      @busy << [ user.id, period_id ]
      Pick.new(user, free.empty? ? [ "concurrent_conflict" ] : [])
    end
  end
end
