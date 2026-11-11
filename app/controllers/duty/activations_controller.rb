# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Duty
  # Halaman guru piket. Hanya aktivasi yang ditugaskan kepada pengguna yang bisa dibuka (selain itu 404).
  class ActivationsController < ApplicationController
    require_role :guru_piket

    def index
      @activations = current_user.duty_activations.open.from_date(Date.current).with_details.ordered_by_slot.to_a
    end

    def show
      @activation = current_user.duty_activations.with_details.find(params[:id])
    end

    def worksheet
      kit = current_user.duty_activations.find(params[:id]).kit
      return head :not_found unless kit&.worksheet&.attached?
      send_data kit.worksheet.download, filename: kit.worksheet.filename.to_s, type: "application/pdf", disposition: "attachment"
    end
  end
end
