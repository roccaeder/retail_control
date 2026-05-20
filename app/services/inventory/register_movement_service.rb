module Inventory
  class RegisterMovementService
    Result = Data.define(:success, :movement, :errors)

    OUTFLOWS = %i[sale waste].freeze

    def self.call(product:, quantity:, movement_type:, origin: nil, description: nil)
      new(product:, quantity:, movement_type:, origin:, description:).call
    end

    def call
      ActiveRecord::Base.transaction do
        movement = product.stock_movements.create!(
          account:       product.account,
          quantity:      quantity,
          movement_type: movement_type,
          origin:        origin,
          description:   description
        )
        delta = OUTFLOWS.include?(movement_type.to_sym) ? -quantity : quantity
        new_stock = product.stock + delta
        if new_stock < 0
          product.errors.add(:base, "Stock insuficiente para #{product.name}. Disponible: #{product.stock}")
          raise ActiveRecord::RecordInvalid.new(product)
        end
        product.update_column(:stock, new_stock)
        Result.new(success: true, movement:, errors: [])
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, movement: nil, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :product, :quantity, :movement_type, :origin, :description

    def initialize(product:, quantity:, movement_type:, origin: nil, description: nil)
      @product       = product
      @quantity      = quantity.to_i
      @movement_type = movement_type
      @origin        = origin
      @description   = description
    end
  end
end
