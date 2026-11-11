# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Curriculum
  class SchoolsController < BaseController
    def show
      @school = current_school
    end

    def update
      @school = current_school
      days = Array(params.dig(:school, :active_days)).map(&:to_i)
      if @school.update(name: params.dig(:school, :name), active_days: days.uniq.sort)
        redirect_to curriculum_school_path, notice: "Pengaturan sekolah disimpan."
      else
        render :show, status: :unprocessable_entity
      end
    end
  end
end
