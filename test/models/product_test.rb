require "test_helper"

class ProductTest < ActiveSupport::TestCase
  setup do
    setup_tenant
  end

  teardown do
    teardown_tenant
  end

  test "válido con datos correctos" do
    product = Product.new(
      name: "Producto Test", sku: "ADE-999",
      cost_price: 1.0, sale_price: 1.5, stock: 10,
      account: default_account
    )
    assert product.valid?
  end

  test "inválido sin nombre" do
    product = Product.new(cost_price: 1.0, sale_price: 1.5, stock: 10, account: default_account)
    assert_not product.valid?
  end

  test "el mismo SKU en distinta cuenta es válido" do
    sku_existente = products(:coca_cola).sku
    # Entramos en el scope de la otra cuenta para que acts_as_tenant no interfiera.
    ActsAsTenant.with_tenant(other_account) do
      product = Product.new(
        name: "X", sku: sku_existente,
        cost_price: 1, sale_price: 2, stock: 5,
        account: other_account
      )
      assert product.valid?, product.errors.full_messages.to_sentence
    end
  end

  test "el mismo SKU en la misma cuenta es inválido" do
    sku_existente = products(:coca_cola).sku
    product = Product.new(
      name: "X", sku: sku_existente,
      cost_price: 1, sale_price: 2, stock: 5,
      account: default_account
    )
    assert_not product.valid?
    assert product.errors[:sku].any?
  end

  test "solo devuelve productos del tenant actual" do
    assert_not_includes Product.all, products(:harina)
  end
end
