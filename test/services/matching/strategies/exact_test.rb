require "test_helper"

class Matching::Strategies::ExactTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @product = create(:product, account: @account, name: "Coca Cola 500ml")
  end

  teardown { teardown_tenant }

  test "encuentra un match case-insensitive" do
    candidates = call("COCA COLA 500ML")
    assert_equal [ @product ], candidates.map(&:product)
    assert_equal 1.0, candidates.first.score
    assert_equal :exact, candidates.first.strategy
  end

  test "no encuentra nada si difiere en espacios o unidades" do
    assert_empty call("Coca Cola 500 ml")
    assert_empty call("Coca-Cola 500ml")
  end

  test "no encuentra nada para un producto que no existe" do
    assert_empty call("Producto Inexistente")
  end

  test "entrada en blanco no encuentra nada" do
    assert_empty call("")
  end

  test "no ve productos de otro tenant" do
    other_account = create(:account)
    ActsAsTenant.with_tenant(other_account) { create(:product, account: other_account, name: "Coca Cola 500ml") }

    assert_equal [ @product ], call("Coca Cola 500ml").map(&:product)
  end

  private

  def call(raw_name)
    Matching::Strategies::Exact.call(raw_name:, normalized_name: Matching::Normalizer.call(raw_name))
  end
end
