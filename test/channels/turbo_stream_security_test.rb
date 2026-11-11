# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

# Pelanggan hanya bisa mengikuti stream yang namanya bertanda tangan (dibuat server untuk halaman miliknya).
class TurboStreamSecurityTest < ActionCable::Channel::TestCase
  tests Turbo::StreamsChannel

  test "nama stream tanpa tanda tangan ditolak" do
    subscribe signed_stream_name: "duty_1"
    assert subscription.rejected?
  end

  test "tanda tangan palsu ditolak" do
    subscribe signed_stream_name: "ZHV0eV8x--abcdef"
    assert subscription.rejected?
  end

  test "nama stream bertanda tangan sah diterima" do
    subscribe signed_stream_name: Turbo.signed_stream_verifier.generate("duty_1")
    assert subscription.confirmed?
    assert_has_stream "duty_1"
  end
end
