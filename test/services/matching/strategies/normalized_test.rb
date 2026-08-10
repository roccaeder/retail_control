require "test_helper"

class Matching::Strategies::NormalizedTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @product = create(:product, account: @account, name: "Leche Gloria 400grs")
  end

  teardown { teardown_tenant }

  test "encuentra un match cuando solo difiere el formato de la unidad" do
    candidates = call("leche gloria 400 GR")
    assert_equal [ @product ], candidates.map(&:product)
    assert_equal 1.0, candidates.first.score
    assert_equal :normalized, candidates.first.strategy
  end

  test "encuentra un match cuando difieren tildes y guiones" do
    assert_equal [ @product ], call("Léche-Gloria 400Gramos").map(&:product)
  end

  test "no encuentra nada si el texto no coincide tras normalizar" do
    assert_empty call("Leche Gloria 500grs")
  end

  test "no encuentra nada para una entrada en blanco" do
    assert_empty call("")
  end

  test "no ve productos de otro tenant" do
    other_account = create(:account)
    ActsAsTenant.with_tenant(other_account) { create(:product, account: other_account, name: "Leche Gloria 400grs") }

    assert_equal [ @product ], call("Leche Gloria 400grs").map(&:product)
  end

  private

  def call(raw_name)
    Matching::Strategies::Normalized.call(raw_name:, normalized_name: Matching::Normalizer.call(raw_name))
  end
end
