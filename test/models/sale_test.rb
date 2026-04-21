require "test_helper"

class SaleTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  setup do
    @account  = create(:account)
    @customer = create(:customer, account: @account)
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  # ── Estructura y Base (Usando ActiveRecord/ActiveModel Matchers) ───────────
  describe "database and associations" do
    let(:sale) { Sale.new }

    # ActiveRecord Matchers
    it { assert_matcher belong_to(:customer), sale }
    it { assert_matcher belong_to(:account), sale }
    it { assert_matcher have_many(:sale_items).dependent(:destroy), sale }
    it { assert_matcher accept_nested_attributes_for(:sale_items), sale }
    
    # ActiveModel Matchers
    it { assert_matcher have_many(:sale_items).dependent(:destroy), sale }
    it { assert_matcher have_many(:payments).dependent(:destroy), sale }
    it { assert_matcher accept_nested_attributes_for(:sale_items), sale }
  end

  describe "enums" do
    let(:sale) { Sale.new }

    it "defines status with correct values" do
      assert_matcher define_enum_for(:status).with_values(paid: 0, pending: 1, partial: 2), sale
    end

    it "defines payment_method with correct values" do
      assert_matcher define_enum_for(:payment_method).with_values(cash: 0, credit: 1, transfer: 2), sale
    end
  end

  # ── Lógica de Negocio (Unit Testing puro) ─────────────────────────────────
  describe "#balance_due" do
    test "calculates the remaining balance accurately" do
      sale = create(:sale, total: 100.0)
      create(:payment, sale: sale, amount: 40.5)
      
      # Usar assert_in_delta para floats/decimals es mejor práctica
      assert_in_delta 59.5, sale.balance_due, 0.001
    end
  end

  describe "callbacks & state machine logic" do
    test "automatically sets status to paid for immediate payments" do
      sale = build(:sale, on_credit: false)
      sale.save # dispara callbacks
      assert_predicate sale, :paid?
    end

    test "generates a unique business code on creation" do
      sale = create(:sale, code: nil)
      assert_match /VTA-\d{4}/, sale.code
    end
  end

  # ── Seguridad y Aislamiento ───────────────────────────────────────────────
  describe "multi-tenancy isolation" do
    test "querying sales should be scoped to the current account" do
      other_account = create(:account)
      ActsAsTenant.with_tenant(other_account) { create(:sale) }
      
      create(:sale) # Venta del tenant actual (@account)
      
      assert_equal 1, Sale.count
    end
  end
end
