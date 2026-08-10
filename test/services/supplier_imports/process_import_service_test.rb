require "test_helper"

class SupplierImports::ProcessImportServiceTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @supplier = create(:supplier, account: @account)
  end

  teardown { teardown_tenant }

  test "procesa un CSV bien formado: crea una resolution por fila y cuenta cada status" do
    create(:product, account: @account, name: "Coca Cola 500ml")

    supplier_import = build_import(<<~CSV)
      nombre,precio
      COCA COLA 500ML,3.50
      Producto Totalmente Ajeno Sin Relacion,1.00
    CSV

    result = SupplierImports::ProcessImportService.call(supplier_import:)

    assert result.success
    assert_equal 2, Resolution.count
    assert supplier_import.reload.completed?
    assert_equal 2, supplier_import.total_rows
    assert_equal 1, supplier_import.auto_matched_count
    assert_equal 1, supplier_import.needs_review_count
    assert_equal 0, supplier_import.unmatched_count
  end

  test "guarda raw_row, raw_name, normalized_name y candidates en cada resolution" do
    product = create(:product, account: @account, name: "Coca Cola 500ml")
    supplier_import = build_import("nombre,precio\nCOCA COLA 500ML,3.50\n")

    SupplierImports::ProcessImportService.call(supplier_import:)
    resolution = Resolution.last

    assert_equal product, resolution.product
    assert_equal "COCA COLA 500ML", resolution.raw_name
    assert_equal "coca cola 500ml", resolution.normalized_name
    assert_equal({ "nombre" => "COCA COLA 500ML", "precio" => "3.50" }, resolution.raw_row)
    assert_equal "exact", resolution.strategy
    assert resolution.candidates.any?
  end

  test "unmatched cuando el catálogo está vacío" do
    supplier_import = build_import("nombre,precio\nCualquier Cosa,1.00\n")

    SupplierImports::ProcessImportService.call(supplier_import:)

    assert_equal 1, supplier_import.reload.unmatched_count
    assert_equal "unmatched", Resolution.last.status
  end

  test "falla el import completo si el CSV no tiene columna de nombre reconocible" do
    supplier_import = build_import("codigo,precio\nABC,1.00\n")

    result = SupplierImports::ProcessImportService.call(supplier_import:)

    assert_not result.success
    assert supplier_import.reload.failed?
    assert supplier_import.error_message.present?
    assert_empty Resolution.all
  end

  test "una fila que falla al persistir no bloquea el resto del import" do
    create(:product, account: @account, name: "Coca Cola 500ml")
    supplier_import = build_import(<<~CSV)
      nombre,precio
      BOOM,1.00
      COCA COLA 500ML,3.50
    CSV

    # No mocking gem is available under Minitest 6 here (minitest-mock isn't
    # installed), so this swaps the method body directly and restores it —
    # plain Ruby, no new dependency for one test.
    original_call = Matching::Normalizer.method(:call)
    Matching::Normalizer.define_singleton_method(:call) do |text|
      text == "BOOM" ? raise("normalizer boom") : original_call.call(text)
    end

    result = SupplierImports::ProcessImportService.call(supplier_import:)

    assert result.success
    assert supplier_import.reload.completed?
    assert_equal 1, Resolution.count
    # total_rows reflects every row the parser found (2), independent of
    # whether persisting it succeeded — that gap is how a silently-dropped
    # row would be noticed.
    assert_equal 2, supplier_import.total_rows
  ensure
    Matching::Normalizer.define_singleton_method(:call, original_call) if original_call
  end

  test "marca processing mientras corre y completed al terminar" do
    supplier_import = build_import("nombre,precio\nCoca Cola 500ml,1.00\n")
    assert supplier_import.pending?

    SupplierImports::ProcessImportService.call(supplier_import:)

    assert supplier_import.reload.completed?
  end

  test "marca failed con el mensaje si ocurre un error fuera del procesamiento por fila" do
    supplier_import = build_import("nombre,precio\nCoca Cola 500ml,1.00\n")

    def supplier_import.update!(**kwargs)
      raise "boom inesperado" if kwargs[:status] == :completed
      super
    end

    result = SupplierImports::ProcessImportService.call(supplier_import:)

    assert_not result.success
    assert supplier_import.reload.failed?
    assert_equal "boom inesperado", supplier_import.error_message
  end

  private

  def build_import(csv_content)
    supplier_import = create(:supplier_import, account: @account, supplier: @supplier)
    supplier_import.file.attach(
      io: StringIO.new(csv_content),
      filename: "test.csv",
      content_type: "text/csv"
    )
    supplier_import
  end
end
