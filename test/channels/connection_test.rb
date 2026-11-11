# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "tanpa sesi login koneksi ditolak" do
    assert_reject_connection { connect }
  end

  test "sesi tidak dikenal ditolak" do
    cookies.signed[:session_id] = 0
    assert_reject_connection { connect }
  end

  test "sesi sah diterima dan dikenali sebagai penggunanya" do
    session = users(:guru_piket).sessions.create!
    cookies.signed[:session_id] = session.id
    connect
    assert_equal users(:guru_piket), connection.current_user
  end
end
