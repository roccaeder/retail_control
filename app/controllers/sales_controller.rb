class SalesController < ApplicationController
  before_action :authenticate_user!
  layout "erp"

  def index
    @sales = Sale.includes(:customer).order(created_at: :desc)
  end
end
