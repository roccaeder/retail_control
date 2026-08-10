module Resolutions
  # Used when a needs_review row genuinely isn't in the catalog yet: creates
  # the Product from the reviewer's input and confirms the Resolution
  # against it in the same transaction, so a failed Product save never
  # leaves the resolution half-confirmed.
  class CreateProductAndConfirmService
    Result = Data.define(:success, :resolution, :errors)

    def self.call(**kwargs) = new(**kwargs).call

    def initialize(resolution:, reviewed_by:, product_attributes:)
      @resolution = resolution
      @reviewed_by = reviewed_by
      @product_attributes = product_attributes
    end

    def call
      ActiveRecord::Base.transaction do
        product = Product.create!(product_attributes.merge(account: resolution.account))
        resolution.update!(status: :confirmed, product:, reviewed_by:, reviewed_at: Time.current)
      end

      Result.new(success: true, resolution:, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, resolution:, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :resolution, :reviewed_by, :product_attributes
  end
end
