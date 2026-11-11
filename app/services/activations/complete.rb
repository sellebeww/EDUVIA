# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Activations
  # Guru piket menyelesaikan aktivasi: kit menjadi "terpakai" dan hasil kembali ke guru pemilik materi.
  # Idempoten: menyelesaikan dua kali tidak mengubah apa pun. Hanya guru piket penerima yang boleh.
  class Complete
    Result = Struct.new(:ok, :activation, :already, :error, keyword_init: true) do
      def ok? = ok
    end

    def self.call(**args) = new(**args).call

    def initialize(activation:, actor:)
      @activation, @actor = activation, actor
    end

    def call
      return failure("Hanya guru piket penerima yang dapat menyelesaikan.") unless @actor&.guru_piket? && @activation.invigilator_id == @actor.id

      already = false
      Activation.transaction do
        @activation.with_lock do
          if @activation.completed?
            already = true
          else
            @activation.update!(completed_at: Time.current)
            @activation.kit&.complete!
          end
        end
      end
      broadcast unless already
      Result.new(ok: true, activation: @activation, already: already)
    rescue Kit::InvalidTransition => e
      Rails.logger.warn("[Activations::Complete] #{e.message}")
      failure("Status kit tidak sesuai. Hubungi wakil kurikulum.")
    end

    private
      def broadcast
        Broadcaster.refresh(school: @activation.school_class.school, invigilator_ids: [ @activation.invigilator_id ],
                            teacher_ids: [ @activation.absence.teacher_id ])
        Broadcaster.notify_result(@activation)
      end

      def failure(error) = Result.new(ok: false, activation: @activation, already: false, error: error)
  end
end
