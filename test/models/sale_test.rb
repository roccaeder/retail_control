require "test_helper"

class SaleTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  setup do
    @account  = create(:account)
    @customer = create(:customer, account: @account)
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    let(:sale) { Sale.new }

    it { assert_matcher have_many(:sale_items).dependent(:destroy), sale }
    it { assert_matcher have_many(:payments).dependent(:destroy), sale }
    it { assert_matcher accept_nested_attributes_for(:sale_items), sale }
  end

  # ── Enums ─────────────────────────────────────────────────────────────────
  describe "enums" do
    let(:sale) { Sale.new }

    it "defines status with correct values" do
      assert_matcher define_enum_for(:status).with_values(paid: 0, pending: 1, partial: 2), sale
    end

    it "defines payment_method with correct values" do
      assert_matcher define_enum_for(:payment_method).with_values(cash: 0, credit: 1, transfer: 2), sale
    end
  end

  # ── Validations ───────────────────────────────────────────────────────────
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

  # ── assign_generic_customer ───────────────────────────────────────────────
  describe "assign_generic_customer" do
    test "assigns Consumidor Final when no customer and not on credit" do
      sale = build(:sale, on_credit: false)
      sale.customer = nil
      sale.customer_id = nil
      sale.valid?
      assert_equal "Consumidor Final", sale.customer.name
    end

    test "does not create a duplicate Consumidor Final" do
      existing = create(:customer, account: @account, name: "Consumidor Final", debt_limit: 0, current_debt: 0)
      sale = build(:sale, on_credit: false)
      sale.customer = nil
      sale.customer_id = nil
      sale.valid?
      assert_equal existing.id, sale.customer.id
    end

    test "does not override an explicitly selected customer" do
      sale = build(:sale, customer: @customer, on_credit: false)
      sale.valid?
      assert_equal @customer, sale.customer
    end

    test "does not assign generic customer for credit sales" do
      sale = build(:sale, on_credit: true)
      sale.customer = nil
      sale.customer_id = nil
      sale.valid?
      assert_nil sale.customer
    end
  end

  # ── sale_items_present ────────────────────────────────────────────────────
  describe "sale_items_present" do
    test "is invalid with no items" do
      sale = build(:sale)
      sale.sale_items = []
      assert_not sale.valid?
      assert_includes sale.errors[:base], "Agrega al menos un producto para registrar la venta."
    end

    test "is valid with at least one item" do
      product = create(:product, account: @account)
      sale = build(:sale)
      sale.sale_items.build(product: product, quantity: 1, unit_price: 10.0, discount: 0.0, account: @account)
      assert sale.valid?
    end
  end

  # ── credit_requires_real_customer ─────────────────────────────────────────
  describe "credit_requires_real_customer" do
    test "is invalid on credit with no customer" do
      sale = build(:sale, on_credit: true, amount_received: 10)
      sale.customer = nil
      sale.customer_id = nil
      sale.valid?
      assert_includes sale.errors[:customer], "debe ser un cliente real para ventas a crédito"
    end

    test "is invalid on credit with Consumidor Final as customer" do
      generic = create(:customer, account: @account, name: "Consumidor Final", debt_limit: 0, current_debt: 0)
      sale = build(:sale, customer: generic, on_credit: true, amount_received: 10)
      sale.valid?
      assert_includes sale.errors[:customer], "debe ser un cliente real para ventas a crédito"
    end

    test "is valid on credit with a real named customer" do
      product = create(:product, account: @account)
      sale = build(:sale, customer: @customer, on_credit: true, amount_received: 10)
      sale.sale_items.build(product: product, quantity: 1, unit_price: 10.0, discount: 0.0, account: @account)
      assert sale.valid?
    end
  end

  # ── amount_received_valid_for_credit ──────────────────────────────────────
  describe "amount_received_valid_for_credit" do
    test "is invalid on credit when amount_received is zero" do
      sale = build(:sale, customer: @customer, on_credit: true, amount_received: 0)
      sale.valid?
      assert_includes sale.errors[:amount_received], "debe ser mayor a 0 para ventas a crédito"
    end

    test "is invalid on credit when amount_received is nil" do
      sale = build(:sale, customer: @customer, on_credit: true, amount_received: nil)
      sale.valid?
      assert_includes sale.errors[:amount_received], "debe ser mayor a 0 para ventas a crédito"
    end

    test "is valid on credit when amount_received is greater than zero" do
      product = create(:product, account: @account)
      sale = build(:sale, customer: @customer, on_credit: true, amount_received: 5.0)
      sale.sale_items.build(product: product, quantity: 1, unit_price: 10.0, discount: 0.0, account: @account)
      assert sale.valid?
    end
  end

  # ── #balance_due ──────────────────────────────────────────────────────────
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

  # ── auto_set_status ───────────────────────────────────────────────────────
  describe "auto_set_status" do
    test "sets status to paid when not on credit" do
      sale = create(:sale, on_credit: false)
      assert_predicate sale, :paid?
    end

    test "sets status to pending when on credit" do
      sale = create(:sale, on_credit: true, amount_received: 10)
      assert_predicate sale, :pending?
    end

    test "re-evaluates status when on_credit changes on update" do
      sale = create(:sale, customer: @customer, on_credit: false)
      assert_predicate sale, :paid?
      sale.update!(on_credit: true)
      assert_predicate sale, :pending?
    end
  end

  # ── generate_code ─────────────────────────────────────────────────────────
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

  # ── set_sale_date ─────────────────────────────────────────────────────────
  describe "set_sale_date" do
    test "sets sale_date to current datetime on create" do
      freeze_time do
        sale = create(:sale)
        assert_equal Time.current, sale.sale_date
      end
    end

    test "always overwrites sale_date with current time on create" do
      freeze_time do
        sale = create(:sale, sale_date: 3.days.ago)
        assert_equal Time.current, sale.sale_date
      end
    end
  end

  # ── update_product_stock ──────────────────────────────────────────────────
  describe "update_product_stock" do
    setup do
      @product = create(:product, account: @account, stock: 10)
    end

    test "reduces stock for each sale item on create" do
      sale = build(:sale, account: @account, customer: @customer)
      sale.sale_items.build(product: @product, quantity: 3, unit_price: @product.sale_price, discount: 0.0, account: @account)
      sale.save!
      assert_equal 7, @product.reload.stock
    end

    test "raises RecordInvalid and adds error when stock is insufficient" do
      sale = build(:sale, account: @account, customer: @customer)
      sale.sale_items.build(product: @product, quantity: 15, unit_price: @product.sale_price, discount: 0.0, account: @account)

      assert_raises(ActiveRecord::RecordInvalid) { sale.save! }
      assert_match /Stock insuficiente para #{@product.name}/, sale.errors[:base].to_s
    end
  end

  # ── Scopes de búsqueda ────────────────────────────────────────────────────
  describe "search scope" do
    test "returns sales matching by code" do
      sale = create(:sale, code: "VTA-0099")
      other = create(:sale, code: "VTA-0001")
      assert_includes Sale.search("VTA-0099"), sale
      assert_not_includes Sale.search("VTA-0099"), other
    end

    test "returns sales matching by customer name" do
      named = create(:customer, account: @account, name: "Pepito Grillo")
      sale  = create(:sale, customer: named)
      assert_includes Sale.search("Pepito"), sale
    end

    test "returns all sales when query is blank" do
      create(:sale)
      assert_equal Sale.count, Sale.search("").count
      assert_equal Sale.count, Sale.search(nil).count
    end
  end

  describe "by_status scope" do
    test "filters paid sales" do
      paid    = create(:sale, on_credit: false)
      pending = create(:sale, on_credit: true, amount_received: 5)

      assert_includes Sale.by_status("paid"), paid
      assert_not_includes Sale.by_status("paid"), pending
    end

    test "pending filter includes both pending and partial sales" do
      pending = create(:sale, on_credit: true, amount_received: 5)
      partial = create(:sale, :partial, account: @account)
      paid    = create(:sale, on_credit: false)

      result = Sale.by_status("pending")
      assert_includes result, pending
      assert_includes result, partial
      assert_not_includes result, paid
    end

    test "returns all sales when status is blank" do
      create(:sale)
      assert_equal Sale.count, Sale.by_status("").count
      assert_equal Sale.count, Sale.by_status(nil).count
    end

    test "returns all sales when status is not a valid key" do
      create(:sale)
      assert_equal Sale.count, Sale.by_status("invalid").count
    end
  end

  # ── link_stock_movement_origins ───────────────────────────────────────────
  describe "link_stock_movement_origins" do
    test "es no-op cuando @new_movement_ids está vacío" do
      sale = create(:sale, account: @account, customer: @customer)
      sale.instance_variable_set(:@new_movement_ids, [])
      assert_no_difference -> { StockMovement.count } do
        sale.send(:link_stock_movement_origins)
      end
    end

    test "crea la venta y el stock_movement queda vinculado al sale" do
      sale = create(:sale, account: @account, customer: @customer)
      movement = StockMovement.where(origin_type: "Sale", origin_id: sale.id).first
      assert_not_nil movement
      assert_equal sale.id, movement.origin_id
    end
  end

  # ── Multi-tenancy ─────────────────────────────────────────────────────────
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
