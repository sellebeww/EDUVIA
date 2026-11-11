# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Content Security Policy: hanya sumber dari origin sendiri. Skrip modul (importmap) memakai nonce per permintaan.
# style-src mengizinkan atribut style inline karena grafik memakai variabel CSS (--w, --h) dan keadaan animasi.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src :self
    policy.img_src :self, :data
    policy.object_src :none
    policy.script_src :self
    policy.style_src :self, :unsafe_inline
    policy.connect_src :self, "ws:", "wss:" # Action Cable (Turbo Streams)
    policy.frame_ancestors :none
    policy.base_uri :self
    policy.form_action :self
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
