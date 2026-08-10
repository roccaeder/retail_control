class ResolutionsController < ApplicationController
  layout "erp"

  before_action :set_supplier_import
  before_action :set_resolution, only: [ :update ]

  def index
    @resolutions = @supplier_import.resolutions.needs_review.order(:raw_name)
    candidate_product_ids = @resolutions.flat_map { |r| r.candidates.map { |c| c["product_id"] } }
    @products_by_id = Product.where(id: candidate_product_ids).index_by(&:id)
    @all_products = Product.order(:name)
  end

  def update
    result = Resolutions::ConfirmMatchService.call(
      resolution: @resolution,
      reviewed_by: current_user,
      product_id: params[:product_id],
      reject: params[:reject]
    )

    if result.success
      redirect_to supplier_import_resolutions_path(@supplier_import), notice: "Resolución actualizada."
    else
      redirect_to supplier_import_resolutions_path(@supplier_import), alert: result.errors.to_sentence
    end
  end

  private

  def set_supplier_import
    @supplier_import = SupplierImport.find(params[:supplier_import_id])
  end

  def set_resolution
    @resolution = @supplier_import.resolutions.find(params[:id])
  end
end
