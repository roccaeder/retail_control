require "test_helper"

class SupplierImports::ParseFileServiceTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @supplier = create(:supplier, account: @account)
  end

  teardown { teardown_tenant }

  test "parsea un CSV bien formado con encabezado nombre" do
    result = call(<<~CSV)
      nombre,precio
      Coca Cola 500ml,3.50
      Inca Kola 500ml,3.20
    CSV

    assert result.success
    assert_empty result.errors
    assert_equal [ "Coca Cola 500ml", "Inca Kola 500ml" ], result.rows.map(&:raw_name)
  end

  test "reconoce encabezados alternativos para el nombre del producto" do
    %w[nombre name producto product descripcion description].each do |header|
      result = call("#{header},precio\nProducto X,1.00\n")
      assert result.success, "esperaba éxito con encabezado #{header.inspect}"
      assert_equal [ "Producto X" ], result.rows.map(&:raw_name)
    end
  end

  test "el matching de encabezado no distingue mayúsculas ni espacios" do
    result = call("  NOMBRE  ,precio\nProducto X,1.00\n")
    assert result.success
    assert_equal [ "Producto X" ], result.rows.map(&:raw_name)
  end

  test "falla con un mensaje claro si no hay columna de nombre reconocible" do
    result = call("codigo,precio\nABC123,1.00\n")

    assert_not result.success
    assert_empty result.rows
    assert result.errors.first.include?("columna de nombre")
  end

  test "ignora filas en blanco y filas sin nombre" do
    result = call(<<~CSV)
      nombre,precio
      Coca Cola 500ml,3.50

      ,2.00
         ,1.00
      Inca Kola 500ml,3.20
    CSV

    assert result.success
    assert_equal [ "Coca Cola 500ml", "Inca Kola 500ml" ], result.rows.map(&:raw_name)
  end

  test "raw_name está recortado pero raw_row conserva el valor original" do
    result = call("nombre,precio\n  Coca Cola 500ml  ,3.50\n")

    row = result.rows.first
    assert_equal "Coca Cola 500ml", row.raw_name
    assert_equal "  Coca Cola 500ml  ", row.raw_row["nombre"]
  end

  test "tolera un BOM UTF-8 al inicio del archivo" do
    content = "\xEF\xBB\xBFnombre,precio\nCoca Cola 500ml,3.50\n".dup.force_encoding(Encoding::UTF_8)
    result = call(content)

    assert result.success
    assert_equal [ "Coca Cola 500ml" ], result.rows.map(&:raw_name)
  end

  test "falla con un mensaje claro ante un CSV malformado" do
    result = call(%(nombre,precio\n"Coca Cola sin cerrar,3.50\n))

    assert_not result.success
    assert_empty result.rows
    assert result.errors.first.present?
  end

  test "tolera filas con menos columnas que el encabezado" do
    result = call("nombre,precio,marca\nCoca Cola 500ml,3.50\n")

    assert result.success
    assert_equal [ "Coca Cola 500ml" ], result.rows.map(&:raw_name)
  end

  private

  def call(csv_content)
    supplier_import = create(:supplier_import, account: @account, supplier: @supplier)
    supplier_import.file.attach(
      io: StringIO.new(csv_content),
      filename: "test.csv",
      content_type: "text/csv"
    )
    SupplierImports::ParseFileService.call(supplier_import:)
  end
end
