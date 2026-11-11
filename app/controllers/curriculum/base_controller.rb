# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
module Curriculum
  # Dasar semua halaman wakil kurikulum. Semua data di-scope ke sekolah pengguna,
  # sehingga ID dari sekolah lain tidak pernah bisa dimuat (hasilnya 404 / tidak ditemukan).
  class BaseController < ApplicationController
    require_role :wakil_kurikulum

    helper_method :current_school

    private
      def current_school = current_user.school
  end
end
