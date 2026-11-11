# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build(attrs = {})
    User.new({ school: schools(:smp), name: "Tes", email_address: "tes@example.test", password: "rahasia123", role: "guru_mapel" }.merge(attrs))
  end

  test "keempat peran tersedia" do
    assert_equal %w[guru_mapel guru_piket wakil_kurikulum kepala_sekolah], User::ROLES
  end

  test "semua fixture valid dan punya label peran" do
    User::ROLES.each do |role|
      user = users(role)
      assert user.valid?, "#{role}: #{user.errors.full_messages}"
      assert_equal role, user.role
      assert user.role_label.present?
    end
  end

  test "peran di luar daftar ditolak lewat validasi, bukan exception" do
    user = build(role: "siswa")
    assert_not user.valid?
    assert user.errors[:role].any?
  end

  test "peran wajib" do
    assert_not build(role: nil).valid?
  end

  test "nama wajib" do
    assert_not build(name: " ").valid?
  end

  test "email dinormalisasi dan harus unik" do
    assert_equal "tes@example.test", build(email_address: "  TES@Example.TEST ").tap(&:valid?).email_address
    build.save!
    assert_not build(email_address: "TES@example.test").valid?
  end

  test "format email divalidasi" do
    assert_not build(email_address: "bukan-email").valid?
  end

  test "authenticate_by memeriksa kata sandi" do
    assert_equal users(:guru_mapel), User.authenticate_by(email_address: users(:guru_mapel).email_address, password: "password")
    assert_nil User.authenticate_by(email_address: users(:guru_mapel).email_address, password: "salah")
  end
end
