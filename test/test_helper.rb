# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  # Masuk lewat form login sungguhan (semua fixture memakai kata sandi "password").
  def log_in_as(user_or_role)
    user = user_or_role.is_a?(User) ? user_or_role : users(user_or_role)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end
end
