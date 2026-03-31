class CustomersController < ApplicationController
  before_action :authenticate_user!
  layout "erp"

  def index
    @customers = Customer.order(:name)
  end
end
