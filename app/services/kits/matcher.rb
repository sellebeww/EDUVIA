# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Kits
  # Memilih kit untuk sebuah jam pelajaran dari kit milik guru yang berhalangan.
  # Prioritas: kit "disiapkan" (paling lama dibuat dulu), lalu kit "terpakai" (dipakai ulang, paling lama
  # tidak dipakai dulu). Kit "aktif" dilewati karena sedang dipakai. Kit yang sudah dipilih untuk jam lain
  # pada pemanggilan yang sama tidak dipilih lagi (mis. jam ganda mapel yang sama).
  class Matcher
    Match = Struct.new(:kit, :reused, keyword_init: true)

    def initialize(teacher)
      @candidates = teacher.kits.where.not(status: "aktif").to_a # satu query untuk semua jam
      @taken = Set.new
    end

    def match(lesson)
      kit = pick(lesson)
      @taken << kit.id if kit
      Match.new(kit: kit, reused: kit&.terpakai? || false)
    end

    private
      def pick(lesson)
        @candidates
          .select { |k| k.subject_id == lesson.subject_id && k.school_class_id == lesson.school_class_id && !@taken.include?(k.id) }
          .min_by { |k| [ k.disiapkan? ? 0 : 1, (k.disiapkan? ? k.created_at : (k.last_used_at || k.created_at)) ] }
      end
  end
end
