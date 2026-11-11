# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Activations
  # Menyiarkan daftar terbaru lewat Turbo Streams. Dipanggil SETELAH transaksi selesai (commit),
  # dan kegagalan siaran tidak boleh membatalkan aktivasi yang sudah tersimpan.
  module Broadcaster
    module_function

    def refresh(school:, invigilator_ids: [])
      invigilator_ids.compact.uniq.each { |id| duty(id) }
      curriculum(school)
    rescue StandardError => e
      Rails.logger.error("[Activations::Broadcaster] gagal menyiarkan: #{e.class}: #{e.message}")
    end

    def duty(user_id)
      activations = Activation.open.where(invigilator_id: user_id).from_date(Date.current).with_details.ordered_by_slot.to_a
      Turbo::StreamsChannel.broadcast_replace_to(
        "duty_#{user_id}", target: "duty-activations", partial: "duty/activations/list", locals: { activations: activations }
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
