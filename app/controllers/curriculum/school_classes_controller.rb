# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Curriculum
  class SchoolClassesController < ResourceController
    private
      def collection = current_school.school_classes.ordered
      def build_record(attrs = {}) = current_school.school_classes.new(attrs)
      def permitted_params = params.expect(school_class: %i[name grade_level])
      def resource_label = "Kelas"
  end
end
