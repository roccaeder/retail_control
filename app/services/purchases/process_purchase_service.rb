module Purchases
  class ProcessPurchaseService
    Result = Data.define(:success, :purchase, :errors)

    def self.call(purchase:)
      new(purchase:).call
    end

    def call
      ActiveRecord::Base.transaction do
        purchase.purchase_items.each do |item|
          result = Inventory::RegisterMovementService.call(
            product:       item.product,
            quantity:      item.quantity,
            movement_type: :purchase,
            origin:        purchase
          )
          unless result.success
            purchase.errors.add(:base, result.errors.first)
            raise ActiveRecord::RecordInvalid.new(purchase)
          end
          item.product.update_column(:cost_price, item.unit_cost)
        end
        total = purchase.purchase_items.sum { |i| i.quantity * i.unit_cost }
        purchase.update!(status: :received, total: total, received_date: Date.current)
        Result.new(success: true, purchase:, errors: [])
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, purchase: nil, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :purchase

    def initialize(purchase:)
      @purchase = purchase
    end
  end
end
