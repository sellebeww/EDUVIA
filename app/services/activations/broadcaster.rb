# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Activations
  # Menyiarkan daftar terbaru lewat Turbo Streams. Dipanggil SETELAH transaksi selesai (commit),
  # dan kegagalan siaran tidak boleh membatalkan aktivasi yang sudah tersimpan.
  module Broadcaster
    module_function

    def refresh(school:, invigilator_ids: [], teacher_ids: [])
      invigilator_ids.compact.uniq.each { |id| duty(id) }
      teacher_ids.compact.uniq.each { |id| teacher(id) }
      curriculum(school)
    rescue StandardError => e
      Rails.logger.error("[Activations::Broadcaster] gagal menyiarkan: #{e.class}: #{e.message}")
    end

    def duty(user_id)
      activations = Activation.where(invigilator_id: user_id).from_date(Date.current).with_details.ordered_by_slot.to_a
      Turbo::StreamsChannel.broadcast_replace_to(
        "duty_#{user_id}", target: "duty-activations", partial: "duty/activations/list", locals: { activations: activations }
      )
    end

    # Toast untuk guru piket: "Kit baru masuk" (satu toast per guru piket, meringkas beberapa kelas).
    def notify_new_kits(activations)
      activations.select(&:invigilator_id).group_by(&:invigilator_id).each do |user_id, rows|
        labels = rows.map(&:label)
        body = labels.size > 1 ? "#{labels.first} dan #{labels.size - 1} kelas lain" : "#{labels.first} · #{rows.first.slot_label}"
        toast("duty_#{user_id}", title: "Kit baru masuk", body: body)
      end
    rescue StandardError => e
      Rails.logger.error("[Activations::Broadcaster] gagal menyiarkan toast: #{e.class}: #{e.message}")
    end

    # Toast untuk guru mapel: hasil jam kosongnya sudah masuk.
    def notify_result(activation)
      toast("teacher_#{activation.absence.teacher_id}", title: "Hasil masuk", body: "#{activation.label} · #{activation.period.display_name}", tone: "ok")
    rescue StandardError => e
      Rails.logger.error("[Activations::Broadcaster] gagal menyiarkan toast: #{e.class}: #{e.message}")
    end

    def toast(stream, title:, body: nil, tone: "info")
      Turbo::StreamsChannel.broadcast_append_to(stream, target: "toasts", partial: "shared/toast", locals: { title: title, body: body, tone: tone })
    end

    # Dashboard guru mapel: hitungan kit dan hasil terbaru. Kartu diganti utuh lewat partial yang sama dengan halamannya.
    def teacher(user_id)
      user = User.find(user_id)
      results = Activation.results_for(user).with_details.with_stats.order(completed_at: :desc).limit(5).to_a
      Turbo::StreamsChannel.broadcast_replace_to(
        "teacher_#{user_id}", target: "teacher-live", partial: "kits/live", locals: { counts: user.kits.group(:status).count, results: results }
      )
    end

    def curriculum(school)
      activations = Activation.for_school(school).from_date(Date.current).with_details.ordered_by_slot.to_a
      Turbo::StreamsChannel.broadcast_replace_to(
        "curriculum_#{school.id}", target: "curriculum-activations", partial: "curriculum/dashboards/activations", locals: { activations: activations }
      )
    end
  end
end
