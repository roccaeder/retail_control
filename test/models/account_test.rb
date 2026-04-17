require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "válido con nombre y subdominio correcto" do
    account = Account.new(name: "Mi Tienda", subdomain: "mi-tienda")
    assert account.valid?
  end

  test "inválido sin nombre" do
    account = Account.new(subdomain: "mi-tienda")
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "inválido sin subdominio" do
    account = Account.new(name: "Mi Tienda")
    assert_not account.valid?
    assert_includes account.errors[:subdomain], "can't be blank"
  end

  test "subdominio debe ser único" do
    account = Account.new(name: "Otro", subdomain: accounts(:one).subdomain)
    assert_not account.valid?
    assert account.errors[:subdomain].any?
  end

  test "subdominio rechaza caracteres inválidos" do
    [ "Mi Tienda", "MAYUSCULAS", "tiene_guion_bajo", "punto.com" ].each do |sub|
      account = Account.new(name: "X", subdomain: sub)
      assert_not account.valid?, "Se esperaba inválido para subdomain='#{sub}'"
    end
  end

  test "subdominio acepta letras minúsculas, números y guiones" do
    account = Account.new(name: "X", subdomain: "tienda-123")
    assert account.valid?
  end
end
