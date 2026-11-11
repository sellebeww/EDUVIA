# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Curriculum
  class SubjectsController < ResourceController
    private
      def collection = current_school.subjects.ordered
      def build_record(attrs = {}) = current_school.subjects.new(attrs)
      def permitted_params = params.expect(subject: %i[name code])
      def resource_label = "Mapel"
  end
end
