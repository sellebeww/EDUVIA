# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Activations
  # Saat guru piket baru ditugaskan pada suatu tanggal, aktivasi yang menunggu guru piket
  # (karena sebelumnya belum ada yang bertugas) langsung diberikan dan kartunya disiarkan.
  class AssignPending
    def self.call(date:, school:)
      pending = Activation.open.where(invigilator_id: nil).for_school(school).joins(:absence, lesson: :period)
                          .where(absences: { date: date }).order("periods.number").includes(:lesson).to_a
      return [] if pending.empty?

      assigner = Duty::Assigner.new(date: date, school: school)
      assigned = pending.filter_map do |activation|
        pick = assigner.assign(activation.lesson.period_id)
        next unless pick.user

        codes = (activation.warning_codes - %w[no_invigilator concurrent_conflict]) + pick.warning_codes
        activation.update!(invigilator: pick.user, warning_codes: codes)
        activation
      end
      Broadcaster.refresh(school: school, invigilator_ids: assigned.map(&:invigilator_id)) if assigned.any?
      assigned
    end
  end
end
