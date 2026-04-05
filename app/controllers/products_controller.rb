class ProductsController < ApplicationController
  before_action :authenticate_user!
  layout "erp"

  def index
    @products = Product.order(:name)
  end

  def search
    @products = if params[:q].present?
                  Product.where("name ILIKE ? OR sku ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%").limit(10)
                else
                  []
                end

    render layout: false
  end
end
