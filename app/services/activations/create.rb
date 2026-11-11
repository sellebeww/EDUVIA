# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Activations
  # Aktivasi satu tombol: wakil kurikulum menandai guru berhalangan pada satu tanggal, lalu kit yang cocok
  # untuk setiap jam mengajarnya dikirim ke guru piket.
  #
  # Kontrak:
  #   - Hanya wakil kurikulum; guru harus guru_mapel dari sekolah yang sama.
  #   - Tanggal: hari aktif sekolah, dari hari ini sampai 7 hari ke depan.
  #   - Satu transaksi dengan kunci per guru+tanggal. Memanggil dua kali = hasil sama, tanpa data ganda.
  #   - Semua kasus tepi (tanpa kit, tanpa guru piket, kelas kosong bersamaan, kit pakai ulang) menghasilkan
  #     Result berisi peringatan, tidak pernah melempar galat ke pemanggil.
  #   - Siaran Turbo Streams dikirim setelah commit, hanya bila ada aktivasi baru.
  class Create
    WINDOW_DAYS = 7

    Result = Struct.new(:ok, :created, :existing, :warnings, :message, :error, keyword_init: true) do
      def ok? = ok
    end

    def self.call(**args) = new(**args).call

    # Galat validasi tanggal/guru (String) atau nil. Dipakai juga oleh pratinjau.
    def self.validation_error(teacher:, date:, today: Date.current)
      return "Guru belum dipilih." unless teacher
      return "Tanggal belum dipilih." unless date
      return "Tanggal sudah lewat. Pilih hari ini atau sesudahnya." if date < today
      return "Tanggal terlalu jauh. Maksimal #{WINDOW_DAYS} hari ke depan." if date > today + WINDOW_DAYS

      day = I18n.t("date.day_names")[date.wday]
      "#{day} bukan hari aktif sekolah." unless teacher.school.active_days.include?(date.cwday)
    end

    def initialize(actor:, teacher:, date:, reason:, note: nil, today: Date.current)
      @actor, @teacher, @date, @reason, @note, @today = actor, teacher, date, reason, note.presence, today
    end

    def call
      return failure("Hanya wakil kurikulum yang boleh mengaktifkan kit.") unless @actor&.wakil_kurikulum?
      return failure("Guru tidak ditemukan.") unless @teacher&.guru_mapel? && @teacher.school_id == @actor.school_id
      if (error = self.class.validation_error(teacher: @teacher, date: @date, today: @today))
        return failure(error)
      end

      result = nil
      ActiveRecord::Base.transaction do
        lock_teacher_day
        result = persist
        raise ActiveRecord::Rollback unless result.ok?
      end
      broadcast(result) if result.ok? && result.created.any?
      result
    rescue Kit::InvalidTransition, ActiveRecord::RecordNotUnique => e
      Rails.logger.warn("[Activations::Create] konflik: #{e.class}: #{e.message}")
      failure("Data berubah saat diproses. Silakan coba lagi.")
    end

    private
      # Kunci per guru+tanggal: dua klik/tab dieksekusi berurutan, bukan paralel.
      def lock_teacher_day
        ActiveRecord::Base.connection.execute("SELECT pg_advisory_xact_lock(#{@teacher.id.to_i}, #{@date.jd.to_i})")
      end

      def persist
        plan = Plan.new(teacher: @teacher, date: @date)
        if plan.empty?
          return Result.new(ok: true, created: [], existing: [], warnings: [], message: "#{@teacher.name} tidak mengajar pada #{label_date}. Tidak ada kelas yang perlu diaktifkan.")
        end

        absence = Absence.find_by(teacher: @teacher, date: @date) || Absence.new(teacher: @teacher, date: @date, reason: @reason, note: @note, created_by: @actor)
        return failure(absence.errors.full_messages.to_sentence) unless absence.persisted? || absence.save

        now = Time.current
        created = plan.items.reject(&:existing?).map { |item| create_activation(absence, item, now) }
        existing = plan.items.select(&:existing?).map(&:existing)
        Result.new(ok: true, created: created, existing: existing, warnings: created.flat_map { |a| warnings_for(a) }, message: message(created, existing))
      end

      def create_activation(absence, item, now)
        activation = Activation.create!(absence: absence, lesson: item.lesson, kit: item.kit, invigilator: item.invigilator,
                                        activated_at: now, reused: item.reused, warning_codes: item.warning_codes)
        item.reused ? item.kit.reuse! : item.kit&.activate!
        seed_sheets(activation, item.lesson.school_class_id, now)
        activation
      end

      # Lembar kehadiran dan pengumpulan: satu baris per siswa kelas tersebut.
      def seed_sheets(activation, class_id, now)
        student_ids = Student.where(school_class_id: class_id).pluck(:id)
        return if student_ids.empty?

        stamp = { created_at: now, updated_at: now }
        AttendanceRecord.insert_all(student_ids.map { |id| { activation_id: activation.id, student_id: id, status: "hadir", **stamp } })
        Submission.insert_all(student_ids.map { |id| { activation_id: activation.id, student_id: id, submitted: false, **stamp } })
      end

      def warnings_for(activation)
        context = "#{activation.school_class.name} · #{activation.subject.name} (#{activation.period.display_name})"
        activation.warnings.map { |w| "#{context}: #{w}" }
      end

      def message(created, existing)
        parts = []
        parts << "#{created.size} kelas diaktifkan untuk #{@teacher.name} pada #{label_date}" if created.any?
        parts << "#{existing.size} kelas sudah diaktifkan sebelumnya" if existing.any?
        parts.join(". ") + "."
      end

      def label_date = I18n.l(@date, format: "%A, %d %B %Y")

      def broadcast(result)
        Broadcaster.refresh(school: @teacher.school, invigilator_ids: result.created.map(&:invigilator_id), teacher_ids: [ @teacher.id ])
      end

      def failure(error)
        Result.new(ok: false, created: [], existing: [], warnings: [], error: error)
      end
  end
end
