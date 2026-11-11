# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Pintu masuk: arahkan pengguna ke beranda sesuai perannya.
class DashboardsController < ApplicationController
  def show
    redirect_to home_path_for(current_user)
  end
end
