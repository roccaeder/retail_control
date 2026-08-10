require "test_helper"

class ResolutionTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @supplier = create(:supplier, account: @account)
    @supplier_import = create(:supplier_import, account: @account, supplier: @supplier)
    @product = create(:product, account: @account)
  end

  teardown { teardown_tenant }

  test "válido con atributos mínimos" do
    resolution = build(:resolution, account: @account, supplier_import: @supplier_import)
    assert resolution.valid?
  end

  test "inválido sin raw_name" do
    resolution = build(:resolution, account: @account, supplier_import: @supplier_import, raw_name: nil)
    assert_not resolution.valid?
    assert resolution.errors[:raw_name].any?
  end

  test "inválido sin normalized_name" do
    resolution = build(:resolution, account: @account, supplier_import: @supplier_import, normalized_name: nil)
    assert_not resolution.valid?
    assert resolution.errors[:normalized_name].any?
  end

  test "auto_matched requiere product" do
    resolution = build(:resolution, account: @account, supplier_import: @supplier_import, status: :auto_matched, product: nil)
    assert_not resolution.valid?
    assert resolution.errors[:product].any?
  end

  test "confirmed requiere product" do
    resolution = build(:resolution, account: @account, supplier_import: @supplier_import, status: :confirmed, product: nil)
    assert_not resolution.valid?
    assert resolution.errors[:product].any?
  end

  test "needs_review no requiere product" do
    resolution = build(:resolution, account: @account, supplier_import: @supplier_import, status: :needs_review, product: nil)
    assert resolution.valid?
  end

  test "unmatched no requiere product" do
    resolution = build(:resolution, account: @account, supplier_import: @supplier_import, status: :unmatched, product: nil)
    assert resolution.valid?
  end

  test "enum status incluye los 5 estados" do
    assert_equal %w[needs_review auto_matched unmatched confirmed rejected], Resolution.statuses.keys
  end

  test "enum strategy incluye las 4 estrategias" do
    assert_equal %w[exact normalized trigram llm], Resolution.strategies.keys
  end

  test "candidates guarda el top-N de candidatos" do
    resolution = create(:resolution,
      account: @account,
      supplier_import: @supplier_import,
      candidates: [
        { "product_id" => @product.id, "score" => 0.92, "strategy" => "trigram" },
        { "product_id" => 999, "score" => 0.61, "strategy" => "trigram" }
      ]
    )
    assert_equal 2, resolution.reload.candidates.size
    assert_equal 0.92, resolution.candidates.first["score"]
  end

  test "borrar el product asociado no borra la resolution" do
    resolution = create(:resolution,
      account: @account,
      supplier_import: @supplier_import,
      product: @product,
      status: :confirmed
    )

    assert_no_difference -> { Resolution.count } do
      @product.destroy
    end
    assert_nil resolution.reload.product_id
  end

  test "aislamiento de tenant: no ve resolutions de otro account" do
    other_account = create(:account)
    ActsAsTenant.with_tenant(other_account) do
      other_supplier = create(:supplier, account: other_account)
      other_import = create(:supplier_import, account: other_account, supplier: other_supplier)
      create(:resolution, account: other_account, supplier_import: other_import)
    end
    assert_equal 0, Resolution.count
  end
end
