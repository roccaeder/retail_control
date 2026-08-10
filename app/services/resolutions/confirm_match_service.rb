module Resolutions
  # Records a human's decision on a needs_review Resolution: either confirm
  # a product (one of the suggested candidates, or any other product the
  # reviewer picked) or reject the row as having no match in the catalog.
  class ConfirmMatchService
    Result = Data.define(:success, :resolution, :errors)

    def self.call(resolution:, reviewed_by:, product_id: nil, reject: false)
      new(resolution:, reviewed_by:, product_id:, reject:).call
    end

    def initialize(resolution:, reviewed_by:, product_id:, reject:)
      @resolution = resolution
      @reviewed_by = reviewed_by
      @product_id = product_id
      @reject = ActiveModel::Type::Boolean.new.cast(reject)
    end

    def call
      if reject
        resolution.update!(status: :rejected, product: nil, reviewed_by:, reviewed_at: Time.current)
      else
        resolution.update!(status: :confirmed, product: find_product!, reviewed_by:, reviewed_at: Time.current)
      end

      Result.new(success: true, resolution:, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, resolution:, errors: e.record.errors.full_messages)
    rescue ActiveRecord::RecordNotFound
      Result.new(success: false, resolution:, errors: [ "Selecciona un producto válido." ])
    end

    private

    attr_reader :resolution, :reviewed_by, :product_id, :reject

    def find_product!
      Product.find(product_id)
    end
  end
end
