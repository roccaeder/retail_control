require "test_helper"

class AccountTest < ActiveSupport::TestCase
  # ── Asociaciones (Account es el tenant root, no tiene conflicto) ──────────
  test "has_many users dependent destroy" do
    assert_matcher have_many(:users).dependent(:destroy), Account.new
  end

  test "has_many customers dependent destroy" do
    assert_matcher have_many(:customers).dependent(:destroy), Account.new
  end

  test "has_many products dependent destroy" do
    assert_matcher have_many(:products).dependent(:destroy), Account.new
  end

  test "has_many sales dependent destroy" do
    assert_matcher have_many(:sales).dependent(:destroy), Account.new
  end

  test "has_many payments dependent destroy" do
    assert_matcher have_many(:payments).dependent(:destroy), Account.new
  end

  # ── Validaciones manuales (Account no tiene acts_as_tenant) ──────────────
  test "inválido sin nombre" do
    account = build(:account, name: nil)
    assert_not account.valid?
    assert account.errors[:name].any?
  end

  test "inválido sin subdomain" do
    account = build(:account, subdomain: nil)
    assert_not account.valid?
    assert account.errors[:subdomain].any?
  end

  test "subdomain debe ser único" do
    create(:account, subdomain: "unico")
    duplicate = build(:account, subdomain: "unico")
    assert_not duplicate.valid?
    assert duplicate.errors[:subdomain].any?
  end

  test "subdomain rechaza mayúsculas, espacios y caracteres especiales" do
    [ "Mi Tienda", "MAYUSCULAS", "tiene_guion_bajo", "punto.com" ].each do |sub|
      assert_not build(:account, subdomain: sub).valid?,
                 "Se esperaba inválido para subdomain='#{sub}'"
    end
  end

  test "subdomain acepta letras minúsculas, números y guiones" do
    assert build(:account, subdomain: "tienda-123").valid?
  end

  test "factory genera accounts válidas" do
    assert build(:account).valid?
  end
end
