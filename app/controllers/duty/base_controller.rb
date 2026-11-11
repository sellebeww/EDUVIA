# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Duty
  class BaseController < ApplicationController
    require_role :guru_piket
  end
end
