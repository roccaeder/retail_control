class Sale < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :customer
  has_many :sale_items, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :products, through: :sale_items

  accepts_nested_attributes_for :sale_items, reject_if: :all_blank

  attr_accessor :amount_received

  # pending: aún no se pagó nada, partial: pago parcial, paid: saldado
  enum :status, { paid: 0, pending: 1, partial: 2 }
  enum :payment_method, { cash: 0, credit: 1, transfer: 2 }

  scope :search, ->(q) {
    q.present? ? joins(:customer).where("sales.code ILIKE :q OR customers.name ILIKE :q", q: "%#{q}%") : all
  }
  scope :by_status, ->(s) {
    case s
    when "pending" then where(status: [ :pending, :partial ])
    when ->(v) { v.present? && statuses.key?(v) } then where(status: s)
    else all
    end
  }
  scope :today,     -> { where(sale_date: Time.zone.today.all_day) }

  validates :code, uniqueness: { scope: :account_id }, allow_blank: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }
  validate :sale_items_present
  validate :amount_received_valid_for_credit, if: -> { on_credit? && new_record? }
  validate :credit_requires_real_customer, if: :on_credit?

  before_validation :assign_generic_customer, unless: :on_credit?
  before_validation :auto_set_status
  before_create :generate_code
  before_create :set_sale_date
  before_create :update_product_stock
  after_create  :link_stock_movement_origins

  def balance_due
    (total - payments.sum(:amount)).round(2)
  end

  private

  def assign_generic_customer
    return if customer_id.present?
    self.customer = Customer.find_or_create_by!(name: "Consumidor Final") do |c|
      c.debt_limit   = 0
      c.current_debt = 0
    end
  end

  def sale_items_present
    return if sale_items.reject(&:marked_for_destruction?).any?
    errors.add(:base, "Agrega al menos un producto para registrar la venta.")
  end

  def credit_requires_real_customer
    return if customer.present? && customer.name != "Consumidor Final"
    errors.add(:customer, "debe ser un cliente real para ventas a crédito")
  end

  def amount_received_valid_for_credit
    if amount_received.to_f <= 0
      errors.add(:amount_received, "debe ser mayor a 0 para ventas a crédito")
    end
  end

  def auto_set_status
    self.status = on_credit? ? :pending : :paid
  end

  def generate_code
    return if code.present?

    last_number = Sale.where(account_id: account_id)
                      .where("code ~ ?", "^VTA-[0-9]+$")
                      .maximum("CAST(SUBSTRING(code FROM 5) AS INTEGER)") || 0
    self.code = "VTA-#{(last_number + 1).to_s.rjust(4, '0')}"
  end

  def set_sale_date
    self.sale_date = Time.current
  end

  def update_product_stock
    @new_movement_ids = []
    sale_items.each do |item|
      result = Inventory::RegisterMovementService.call(
        product:       Product.find(item.product_id),
        quantity:      item.quantity.to_i,
        movement_type: :sale
      )
      unless result.success
        errors.add(:base, result.errors.first)
        raise ActiveRecord::RecordInvalid.new(self)
      end
      @new_movement_ids << result.movement.id
    end
  end

  def link_stock_movement_origins
    return if @new_movement_ids.blank?
    StockMovement.where(id: @new_movement_ids)
                 .update_all(origin_type: "Sale", origin_id: id)
  end
end
