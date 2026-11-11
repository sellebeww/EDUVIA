# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Otorisasi sederhana berbasis peran, tanpa gem.
# Pakai di controller:  require_role :wakil_kurikulum, :kepala_sekolah
module Authorization
  extend ActiveSupport::Concern

  class NotAuthorized < StandardError; end

  included do
    rescue_from NotAuthorized, with: :render_forbidden
    helper_method :current_user, :home_path_for
  end

  class_methods do
    def require_role(*roles, **options)
      before_action(**options) { authorize_role!(*roles) }
    end
  end

  private
    def current_user = Current.user

    def authorize_role!(*roles)
      raise NotAuthorized unless current_user && roles.map(&:to_s).include?(current_user.role)
    end

    def render_forbidden
      render "errors/forbidden", status: :forbidden
    end

    def home_path_for(user)
      case user.role
      when "guru_mapel" then kits_path
      when "guru_piket" then duty_root_path
      when "wakil_kurikulum" then curriculum_root_path
      when "kepala_sekolah" then reports_path
      end
    end
end
