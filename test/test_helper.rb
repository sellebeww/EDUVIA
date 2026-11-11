# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "turbo/broadcastable/test_helper"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Dimuat eksplisit: turbo-rails hanya meng-include otomatis bila Action Cable ter-load lebih dulu (urutan tak pasti).
    include Turbo::Broadcastable::TestHelper

    # Menghitung siaran daftar (aksi "replace") pada sebuah stream. Toast (aksi "append") dihitung terpisah.
    def assert_list_broadcasts(stream, count:, &block)
      streams = capture_turbo_stream_broadcasts(stream, &block)
      actual = streams.count { |element| element["action"] == "replace" }
      assert_equal count, actual, "Diharapkan #{count} siaran daftar pada #{stream.inspect}, ada #{actual}"
    end

    # Toast (aksi "append" ke #toasts) yang disiarkan selama blok berjalan.
    def captured_toasts(stream, &block)
      capture_turbo_stream_broadcasts(stream, &block).select { |element| element["action"] == "append" && element["target"] == "toasts" }
    end

    # Jumlah query SQL (tanpa SCHEMA/TRANSACTION) yang dijalankan blok, termasuk yang dilayani query cache
    # (query cache aktif lintas request di tes integrasi). Untuk menjaga halaman bebas N+1.
    def count_queries(&block)
      count = 0
      counter = ->(*, payload) { count += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name]) }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      count
    end

    # Minitest 6 tidak lagi menyertakan Object#stub, jadi helper kecil ini menggantikannya.
    # Mengganti method singleton selama blok berjalan lalu memulihkannya.
    def stub_method(object, name, callable)
      original = object.method(name)
      object.define_singleton_method(name) { |*args, **kwargs, &block| callable.call(*args, **kwargs, &block) }
      yield
    ensure
      object.define_singleton_method(name, original)
    end
  end
end

class ActionDispatch::IntegrationTest
  # Sesi terpisah (browser kedua) yang sudah masuk sebagai peran tertentu.
  def login_session(role)
    open_session { |s| s.post s.session_path, params: { email_address: users(role).email_address, password: "password" } }
  end

  # Masuk lewat form login sungguhan (semua fixture memakai kata sandi "password").
  def log_in_as(user_or_role)
    user = user_or_role.is_a?(User) ? user_or_role : users(user_or_role)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end
end
