class DashboardController < ApplicationController
  before_action :authenticate_user! # Redirige al login si no ha iniciado sesión
  layout "erp" # <--- Esto es vital, le dice que use el Sidebar que crearemos abajo

  def index
    # Aquí buscaremos las ventas y deudas después
  end
end
