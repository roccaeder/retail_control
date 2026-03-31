class ProductsController < ApplicationController
  before_action :authenticate_user!
  layout "erp"

  def index
    @products = Product.order(:name)
  end
end
