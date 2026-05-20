class DashboardController < ApplicationController
  layout "erp"

  def index
    today    = Time.zone.today
    week_ago = today - 6.days
    month_ago = today - 29.days

    @sales_today = Sale.where(sale_date: today.all_day)
    @sales_week  = Sale.where(sale_date: week_ago.beginning_of_day..today.end_of_day)
    @sales_month = Sale.where(sale_date: month_ago.beginning_of_day..today.end_of_day)

    @total_today = @sales_today.sum(:total)
    @total_week  = @sales_week.sum(:total)
    @total_month = @sales_month.sum(:total)
    @count_today = @sales_today.count

    @pending_debt   = Customer.sum(:current_debt)
    @customers_debt = Customer.where("current_debt > 0").count

    @low_stock_count = Product.where("stock < 10 AND stock > 0").count
    @out_of_stock    = Product.where(stock: 0).count

    @top_products = SaleItem
      .joins(:product)
      .select("products.name, SUM(sale_items.quantity) AS total_sold")
      .group("products.id, products.name")
      .order("total_sold DESC")
      .limit(5)

    @customers_near_limit = Customer
      .where("debt_limit > 0 AND current_debt >= debt_limit * 0.8")
      .order(Arel.sql("current_debt / debt_limit DESC"))
      .limit(5)

    @recent_sales = Sale.includes(:customer).order(created_at: :desc).limit(8)
  end
end
