# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Curriculum
  class DashboardsController < BaseController
    def show
      @activations = Activation.for_school(current_school).from_date(Date.current).with_details.ordered_by_slot.to_a
    end
  end
end
