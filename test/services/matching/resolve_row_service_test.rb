require "test_helper"

class Matching::ResolveRowServiceTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @coca_cola = create(:product, account: @account, name: "Coca Cola 500ml")
    @inca_kola = create(:product, account: @account, name: "Inca Kola 500ml")
  end

  teardown { teardown_tenant }

  test "auto_matched cuando el exact strategy encuentra un match" do
    decision = call("COCA COLA 500ML")

    assert_equal :auto_matched, decision.status
    assert_equal @coca_cola, decision.product
    assert_equal :exact, decision.strategy
    assert_equal 1.0, decision.score
  end

  test "auto_matched cuando solo el normalized strategy encuentra un match" do
    decision = call("Coca-Cola 500 ML")

    assert_equal :auto_matched, decision.status
    assert_equal @coca_cola, decision.product
    assert_equal :normalized, decision.strategy
  end

  test "needs_review cuando solo el trigram strategy encuentra algo, sin importar el score" do
    decision = call("Coca Colaa 500ml")

    assert_equal :needs_review, decision.status
    assert_nil decision.product
    assert_nil decision.strategy
    assert_nil decision.score
    assert decision.candidates.first["score"] > 0.7
  end

  test "needs_review incluso con scores muy bajos, sin aplicar ningún piso" do
    decision = call("Producto Totalmente Ajeno Sin Relacion")

    assert_equal :needs_review, decision.status
    assert decision.candidates.any?
    assert decision.candidates.all? { |c| c["score"] < 0.3 }
  end

  test "unmatched solo cuando no hay ningún producto en el catálogo" do
    Product.destroy_all
    decision = call("Cualquier Cosa")

    assert_equal :unmatched, decision.status
    assert_empty decision.candidates
  end

  test "candidates trae como máximo CANDIDATE_LIMIT productos distintos, ordenados por score" do
    4.times { |n| create(:product, account: @account, name: "Coca Cola Variante #{n}") }
    decision = call("Coca Cola 500ml")

    assert_equal Matching::ResolveRowService::CANDIDATE_LIMIT, decision.candidates.size
    scores = decision.candidates.map { |c| c["score"] }
    assert_equal scores.sort.reverse, scores
  end

  test "candidates no repite el mismo producto aunque varias estrategias lo encuentren" do
    decision = call("COCA COLA 500ML")
    product_ids = decision.candidates.map { |c| c["product_id"] }

    assert_equal product_ids.uniq, product_ids
  end

  test "candidates tiene el formato esperado para persistencia" do
    decision = call("COCA COLA 500ML")
    winner = decision.candidates.first

    assert_equal @coca_cola.id, winner["product_id"]
    assert_equal 1.0, winner["score"]
    assert_equal "exact", winner["strategy"]
  end

  private

  def call(raw_name)
    Matching::ResolveRowService.call(raw_name:)
  end
end
