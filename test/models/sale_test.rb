require "test_helper"

class SaleTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  setup do
    @account  = create(:account)
    @customer = create(:customer, account: @account)
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  describe "associations" do
    let(:sale) { Sale.new }

    it { assert_matcher belong_to(:customer), sale }
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

  describe "validations" do
    test "is invalid with a negative total" do
      sale = build(:sale, total: -1)
      assert_not sale.valid?
      assert_includes sale.errors[:total], "must be greater than or equal to 0"
    end

    test "is valid with a zero total" do
      sale = build(:sale, total: 0)
      assert sale.valid?
    end

    test "is invalid when code is duplicated within the same account" do
      create(:sale, code: "VTA-0001")
      duplicate = build(:sale, code: "VTA-0001")
      assert_not duplicate.valid?
      assert_includes duplicate.errors[:code], "has already been taken"
    end

    test "allows the same code across different accounts" do
      other_account = create(:account)
      ActsAsTenant.with_tenant(other_account) { create(:sale, code: "VTA-0001") }
      sale = build(:sale, code: "VTA-0001")
      assert sale.valid?
    end

    test "allows blank code" do
      sale = build(:sale, code: nil)
      assert sale.valid?
    end
  end

  describe "#balance_due" do
    test "returns full total when no payments exist" do
      sale = create(:sale, total: 100.0)
      assert_in_delta 100.0, sale.balance_due, 0.001
    end

    test "returns zero when fully paid" do
      sale = create(:sale, total: 50.0)
      create(:payment, sale: sale, amount: 50.0)
      assert_in_delta 0.0, sale.balance_due, 0.001
    end

    test "returns remaining balance for partial payment" do
      sale = create(:sale, total: 100.0)
      create(:payment, sale: sale, amount: 40.5)
      assert_in_delta 59.5, sale.balance_due, 0.001
    end

    test "rounds result to 2 decimal places" do
      sale = create(:sale, total: 10.0)
      create(:payment, sale: sale, amount: 3.333)
      assert_equal 6.67, sale.balance_due
    end

    test "accumulates multiple payments" do
      sale = create(:sale, total: 100.0)
      create(:payment, sale: sale, amount: 30.0)
      create(:payment, sale: sale, amount: 20.0)
      assert_in_delta 50.0, sale.balance_due, 0.001
    end
  end

  describe "auto_set_status" do
    test "sets status to paid when not on credit" do
      sale = create(:sale, on_credit: false)
      assert_predicate sale, :paid?
    end

    test "sets status to pending when on credit" do
      sale = create(:sale, on_credit: true)
      assert_predicate sale, :pending?
    end

    test "re-evaluates status when on_credit changes on update" do
      sale = create(:sale, on_credit: false)
      assert_predicate sale, :paid?
      sale.update!(on_credit: true)
      assert_predicate sale, :pending?
    end
  end

  describe "generate_code" do
    test "generates a VTA-NNNN formatted code when code is blank" do
      sale = create(:sale, code: nil)
      assert_match(/\AVTA-\d{4}\z/, sale.code)
    end

    test "does not override a provided code" do
      sale = create(:sale, code: "VTA-9999")
      assert_equal "VTA-9999", sale.code
    end

    test "increments code sequentially within the same account" do
      first  = create(:sale, code: nil)
      second = create(:sale, code: nil)
      first_num  = first.code.delete_prefix("VTA-").to_i
      second_num = second.code.delete_prefix("VTA-").to_i
      assert_equal 1, second_num - first_num
    end

    test "ignores non-standard codes when computing the next number" do
      create(:sale, code: "CUSTOM-001")
      sale = create(:sale, code: nil)
      assert_match(/\AVTA-\d{4}\z/, sale.code)
    end

    test "continues sequence from the highest existing VTA code" do
      create(:sale, code: "VTA-0050")
      sale = create(:sale, code: nil)
      assert_equal "VTA-0051", sale.code
    end
  end

  describe "set_sale_date" do
    test "defaults sale_date to today when not provided" do
      sale = create(:sale, sale_date: nil)
      assert_equal Date.current, sale.sale_date
    end

    test "preserves an explicitly provided sale_date" do
      custom_date = Date.new(2025, 1, 15)
      sale = create(:sale, sale_date: custom_date)
      assert_equal custom_date, sale.sale_date
    end
  end

  describe "multi-tenancy isolation" do
    test "scopes Sale.count to the current account" do
      other_account = create(:account)
      ActsAsTenant.with_tenant(other_account) { create(:sale) }
      create(:sale)
      assert_equal 1, Sale.count
    end

    test "cannot find a sale belonging to another account" do
      other_account = create(:account)
      other_sale = ActsAsTenant.with_tenant(other_account) { create(:sale) }
      assert_nil Sale.find_by(id: other_sale.id)
    end
  end
end
