# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Curriculum
  class PeriodsController < ResourceController
    private
      def collection = current_school.periods.ordered
      def build_record(attrs = {}) = current_school.periods.new(attrs)
      def permitted_params = params.expect(period: %i[number label starts_at ends_at recess])
      def resource_label = "Jam pelajaran"

      def default_attributes
        last = current_school.periods.ordered.last
        { number: (last&.number || 0) + 1, starts_at: last&.ends_at }
      end
  end
end
