# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Duty
  class ActivationsController < ApplicationController
    require_role :guru_piket

    def index
    end
  end
end
