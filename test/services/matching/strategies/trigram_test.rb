require "test_helper"

class Matching::Strategies::TrigramTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @coca_cola = create(:product, account: @account, name: "Coca Cola 500ml")
    @inca_kola = create(:product, account: @account, name: "Inca Kola 500ml")
    @leche     = create(:product, account: @account, name: "Leche Gloria 400g")
  end

  teardown { teardown_tenant }

  test "encuentra el producto correcto para un typo leve" do
    candidates = call("Coca Colaa 500ml")
    assert_equal @coca_cola, candidates.first.product
    assert_equal :trigram, candidates.first.strategy
    assert candidates.first.score > 0.7
  end

  test "ordena los candidatos de mayor a menor score" do
    candidates = call("Coca Cola 500ml")
    scores = candidates.map(&:score)
    assert_equal scores.sort.reverse, scores
  end

  test "no aplica ningún piso: devuelve el top-N incluso con scores muy bajos" do
    candidates = call("xyz completamente distinto sin relacion")
    assert_equal 3, candidates.size
    assert candidates.all? { |c| c.score < 0.3 }
  end

  test "limita a TOP_N candidatos" do
    4.times { |n| create(:product, account: @account, name: "Coca Cola Zero #{n}") }
    candidates = call("Coca Cola 500ml")
    assert_equal Matching::Strategies::Trigram::TOP_N, candidates.size
  end

  test "no ve productos de otro tenant" do
    other_account = create(:account)
    ActsAsTenant.with_tenant(other_account) { create(:product, account: other_account, name: "Coca Cola 500ml Idéntico") }

    candidates = call("Coca Cola 500ml")
    assert candidates.none? { |c| c.product.account_id == other_account.id }
  end

  private

  def call(raw_name)
    Matching::Strategies::Trigram.call(raw_name:, normalized_name: Matching::Normalizer.call(raw_name))
  end
end
