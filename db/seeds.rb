# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Limpiar la base de datos antes de empezar
puts "🗑️ Limpiando base de datos..."
SaleItem.destroy_all
Sale.destroy_all
Product.destroy_all
Customer.destroy_all
User.destroy_all

puts "👤 Creando Usuarios (Staff)..."
users_data = [
  { email: 'eder@example.com', password: 'password123', name: 'Eder' },
  { email: 'sebastian@example.com', password: 'password123', name: 'Sebastian' }
]

users_data.each do |u|
  User.find_or_create_by!(email: u[:email]) do |user|
    user.password = u[:password]
    # Si agregaste el campo 'name' a User, descomenta la línea de abajo:
    # user.name = u[:name]
  end
end
puts "✅ Usuarios Eder y Sebastian creados (Password: password123)"

puts "👥 Creando Clientes y Fiados..."
nombres_clientes = [ "Juan Perez", "Maria Garcia", "Tienda La Bendicion", "Comercial Martinez", "Dona Rosa", "Pedro Picapiedra" ]
15.times do |i|
  Customer.create!(
    name: nombres_clientes.sample + " #{i}",
    phone: "9#{rand(10000000..99999999)}",
    debt_limit: [ 500, 1000, 5000 ].sample,
    current_debt: 0
  )
end

puts "📦 Creando Inventario de Productos..."
productos_base = [ "Harina Pan", "Coca Cola 1.5L", "Arroz 1kg", "Aceite Vegetal", "Detergente", "Papel Higienico", "Cerveza Pack", "Cigarrillos" ]
25.times do |i|
  costo = rand(5.0..40.0).round(2)
  Product.create!(
    name: productos_base.sample + " - Lote #{rand(1..100)}",
    sku: "SKU-#{rand(1000..9999)}",
    cost_price: costo,
    sale_price: (costo * 1.3).round(2), # 30% de margen
    stock: rand(5..50)
  )
end

puts "💰 Generando Historial de Ventas..."
customers = Customer.all
products = Product.all

30.times do
  customer = customers.sample
  # Creamos la venta pero sin guardarla aún para calcular totales
  sale = Sale.new(
    customer: customer,
    status: rand(0..1), # 0: paid, 1: pending
    payment_method: rand(0..2), # 0: cash, 1: credit, 2: transfer
    discount_amount: [ 0, 0, 0, 5, 10 ].sample # Mayor probabilidad de 0 descuento
  )

  subtotal_acumulado = 0
  # Cada venta tiene entre 1 y 5 productos distintos
  rand(1..5).times do
    product = products.sample
    cantidad = rand(1..3)
    subtotal_acumulado += (product.sale_price * cantidad)

    sale.sale_items << SaleItem.new(
      product: product,
      quantity: cantidad,
      unit_price: product.sale_price,
      discount: 0
    )
  end

  sale.subtotal = subtotal_acumulado
  sale.total = subtotal_acumulado - sale.discount_amount
  sale.save!

  # Lógica de Deuda: Si la venta es pendiente o crédito, sumamos al cliente
  if sale.status == "pending" || sale.payment_method == "credit"
    customer.update!(current_debt: customer.current_debt + sale.total)
  end
end

puts "🚀 ERP Cargado con éxito!"
