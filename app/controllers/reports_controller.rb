# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
class ReportsController < ApplicationController
  require_role :kepala_sekolah, :wakil_kurikulum

  def index
  end
end
