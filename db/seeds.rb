# Seeds idempotentes para arquitectura multi-tenant.
# Crea 2 cuentas de demostración con datos realistas aislados entre sí.

require "bcrypt"

puts "Limpiando datos existentes..."
SupplierImport.find_each(&:destroy) # purga el archivo adjunto y sus resolutions en cascada
# Orden respetando las foreign keys (hijos antes que padres). StockMovement,
# PurchaseItem, Purchase y Expense faltaban aquí desde que se agregaron sus
# migraciones — sin ellos, un segundo `db:seed` fallaba por FK violation.
[ Payment, SaleItem, StockMovement, PurchaseItem, Purchase, Expense, Sale, Customer, Product, Supplier, User, Account ]
  .each(&:delete_all)

NOMBRES_CLIENTES = [
  "Ana Martínez", "Luis García", "Tienda La Bendición", "Comercial Rodríguez",
  "Doña Rosa", "Pedro Alvarado", "Supermercado El Sol", "Carnicería Don Juan",
  "María López", "Ferretería Central"
].freeze

PRODUCTOS_BASE = [
  { name: "Harina Pan 1kg",       costo: 2.50,  margen: 0.30 },
  { name: "Coca Cola 1.5L",       costo: 1.20,  margen: 0.40 },
  { name: "Arroz Integral 1kg",   costo: 1.80,  margen: 0.25 },
  { name: "Aceite Vegetal 1L",    costo: 3.00,  margen: 0.28 },
  { name: "Detergente 500ml",     costo: 1.50,  margen: 0.35 },
  { name: "Papel Higiénico x4",   costo: 2.00,  margen: 0.30 },
  { name: "Cerveza 355ml Pack x6", costo: 6.00,  margen: 0.20 },
  { name: "Jabón de Lavar 250g",  costo: 0.80,  margen: 0.45 },
  { name: "Azúcar 1kg",           costo: 1.10,  margen: 0.25 },
  { name: "Leche Entera 1L",      costo: 1.30,  margen: 0.22 },
  { name: "Pasta 500g",           costo: 0.90,  margen: 0.33 },
  { name: "Atún en Lata",         costo: 1.60,  margen: 0.38 },
  { name: "Sal 1kg",              costo: 0.50,  margen: 0.60 },
  { name: "Margarina 250g",       costo: 1.40,  margen: 0.29 },
  { name: "Café Molido 250g",     costo: 2.80,  margen: 0.35 }
].freeze

def seed_account(name:, subdomain:, email:, password:, clientes_count:, productos_count:, ventas_count:, incluir_import_proveedor: false)
  puts "\n── Cuenta: #{name} ──"

  account = Account.create!(name: name, subdomain: subdomain)

  ActsAsTenant.with_tenant(account) do
    # Usuario administrador
    User.create!(
      email:    email,
      password: password,
      password_confirmation: password,
      account:  account
    )
    puts "  ✓ Usuario: #{email} / #{password}"

    # Clientes con variedad de deudas y límites
    clientes = clientes_count.times.map do |i|
      Customer.create!(
        name:         NOMBRES_CLIENTES[i % NOMBRES_CLIENTES.size] + (i >= NOMBRES_CLIENTES.size ? " #{i}" : ""),
        phone:        "9#{rand(10_000_000..99_999_999)}",
        debt_limit:   [ 300, 500, 1000, 2000, 5000 ].sample,
        current_debt: 0,
        account:      account
      )
    end
    puts "  ✓ #{clientes.size} clientes"

    # Productos con SKU único por cuenta
    productos = PRODUCTOS_BASE.first(productos_count).map.with_index do |p, i|
      costo = p[:costo] * rand(0.9..1.1).round(2)
      Product.create!(
        name:       p[:name],
        sku:        "#{subdomain.upcase[0, 3]}-#{(i + 1).to_s.rjust(3, '0')}",
        cost_price: costo.round(2),
        sale_price: (costo * (1 + p[:margen])).round(2),
        stock:      rand(10..100),
        account:    account
      )
    end
    puts "  ✓ #{productos.size} productos"

    # Proveedor con una lista de precios pendiente de revisión (demuestra el
    # importador: nombres con mayúsculas/minúsculas mezcladas, unidades
    # inconsistentes, tildes y guiones, y typos leves — como llegaría de
    # verdad de un proveedor).
    proveedor = Supplier.create!(
      name:    "Distribuidora #{name.split.last}",
      phone:   "9#{rand(10_000_000..99_999_999)}",
      account: account
    )
    puts "  ✓ Proveedor: #{proveedor.name}"

    if incluir_import_proveedor
      supplier_import = SupplierImport.new(account: account, supplier: proveedor)
      supplier_import.file.attach(
        io:           Rails.root.join("test/fixtures/files/messy_supplier_products.csv").open,
        filename:     "lista_precios_#{subdomain}.csv",
        content_type: "text/csv"
      )
      supplier_import.save!
      puts "  ✓ Import de proveedor pendiente: #{supplier_import.file.filename}"
    end

    # Ventas históricas con lógica de deuda real.
    # stock_disponible rastrea en memoria lo que le queda a cada producto
    # para no vender más de lo que hay (los pedidos se sirven contra stock
    # real vía Sale#update_product_stock, que lanza RecordInvalid si no
    # alcanza).
    stock_disponible = productos.index_by(&:id).transform_values(&:stock)

    ventas_count.times do |i|
      customer = clientes.sample
      on_credit = [ true, false, false ].sample   # ~33% fiado
      payment_method = on_credit ? :credit : [ :cash, :transfer ].sample
      discount = [ 0, 0, 0, 5, 10, 20 ].sample

      sale_date = Date.today - rand(0..90)

      sale = Sale.new(
        customer:        customer,
        payment_method:  payment_method,
        on_credit:       on_credit,
        discount_amount: discount,
        sale_date:       sale_date,
        account:         account
      )

      subtotal = 0
      rand(1..4).times do
        productos_con_stock = productos.select { |p| stock_disponible[p.id] > 0 }
        next if productos_con_stock.empty?

        product = productos_con_stock.sample
        cantidad = [ rand(1..3), stock_disponible[product.id] ].min
        stock_disponible[product.id] -= cantidad

        subtotal += product.sale_price * cantidad
        sale.sale_items << SaleItem.new(
          product:    product,
          quantity:   cantidad,
          unit_price: product.sale_price,
          discount:   0,
          account:    account
        )
      end
      next if sale.sale_items.empty?

      sale.subtotal = subtotal.round(2)
      sale.total    = [ subtotal - discount, 0 ].max.round(2)
      sale.amount_received = [ sale.total, 0.01 ].max if on_credit # requerido por Sale#amount_received_valid_for_credit
      sale.save!

      if on_credit
        # Pago parcial aleatorio en ~40% de las ventas a crédito
        if rand < 0.4 && sale.total > 10
          pago_parcial = (sale.total * rand(0.2..0.7)).round(2)
          Payments::RegisterPaymentService.call(
            sale:           sale,
            amount:         pago_parcial,
            payment_method: :cash,
            date:           Date.today - rand(0..30)
          )
        end
      else
        # Venta al contado: registrar pago completo
        Payments::RegisterPaymentService.call(
          sale:           sale,
          amount:         sale.total,
          payment_method: payment_method,
          date:           Date.today - rand(0..60)
        )
      end
    end

    puts "  ✓ #{ventas_count} ventas con pagos"
    puts "  ✓ Deuda total activa: $#{Customer.sum(:current_debt).to_f.round(2)}"
  end

  account
end

# ── Cuenta 1: Almacén demo completo ──────────────────────────────────────────
seed_account(
  name:           "Almacén Don Eder",
  subdomain:      "almacen-don-eder",
  email:          "eder@example.com",
  password:       "password123",
  clientes_count: 10,
  productos_count: 15,
  ventas_count:   30,
  incluir_import_proveedor: true
)

# ── Cuenta 2: Segunda tienda (demuestra aislamiento multi-tenant) ─────────────
seed_account(
  name:           "Tienda Sebastián",
  subdomain:      "tienda-sebastian",
  email:          "sebastian@example.com",
  password:       "password123",
  clientes_count: 5,
  productos_count: 8,
  ventas_count:   15
)

puts "\n✅ Seeds cargados exitosamente!"
puts "   Cuenta 1 → eder@example.com / password123"
puts "   Cuenta 2 → sebastian@example.com / password123"
