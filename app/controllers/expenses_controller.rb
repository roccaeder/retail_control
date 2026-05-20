class ExpensesController < ApplicationController
  layout "erp"

  CATEGORIES = [
    "Alquiler", "Servicios básicos", "Sueldos", "Proveedor",
    "Transporte", "Marketing", "Mantenimiento", "Impuestos", "Otros"
  ].freeze

  def index
    @expenses = Expense.includes(:supplier)
                       .order(date: :desc, created_at: :desc)
    @cash_flow = Reports::CashFlowQuery.call(
      account: current_tenant,
      from:    Date.current.beginning_of_month,
      to:      Date.current
    )
    @categories = CATEGORIES
  end

  def new
    @expense = Expense.new(date: Date.current)
    @suppliers  = Supplier.order(:name)
    @categories = CATEGORIES
  end

  def create
    @expense = Expense.new(expense_params)
    @expense.account = current_tenant
    if @expense.save
      redirect_to expenses_path, notice: "Gasto registrado correctamente."
    else
      @suppliers  = Supplier.order(:name)
      @categories = CATEGORIES
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    expense = Expense.find(params[:id])
    expense.destroy
    redirect_to expenses_path, notice: "Gasto eliminado."
  end

  private

  def expense_params
    params.require(:expense).permit(:category, :amount, :date, :description, :supplier_id)
  end
end
