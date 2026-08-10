module SupplierImports
  # Parses a SupplierImport's attached CSV into rows ready for matching.
  # Tolerant of the mess real supplier files show up with: BOM, header
  # casing/whitespace, blank rows, stray quoting. Doesn't touch the
  # database — persisting Resolutions is the job's responsibility.
  class ParseFileService
    Row = Data.define(:raw_name, :raw_row)
    Result = Data.define(:success, :rows, :errors)

    NAME_COLUMN_ALIASES = %w[nombre name producto product descripcion description].freeze

    def self.call(supplier_import:) = new(supplier_import:).call

    def initialize(supplier_import:)
      @supplier_import = supplier_import
    end

    def call
      table = CSV.parse(decoded_content, headers: true, skip_blanks: true, liberal_parsing: true)
      name_column = detect_name_column(table.headers)

      unless name_column
        return failure("No se encontró una columna de nombre de producto (se esperaba alguna de: #{NAME_COLUMN_ALIASES.join(', ')})")
      end

      rows = table.filter_map do |row|
        raw_name = row[name_column].to_s.strip
        next if raw_name.blank?

        Row.new(raw_name:, raw_row: row.to_h)
      end

      Result.new(success: true, rows:, errors: [])
    rescue CSV::MalformedCSVError => e
      failure("El archivo no es un CSV válido: #{e.message}")
    end

    private

    attr_reader :supplier_import

    def decoded_content
      supplier_import.file.download.force_encoding(Encoding::UTF_8).delete_prefix("\xEF\xBB\xBF")
    end

    def detect_name_column(headers)
      headers.find { |header| NAME_COLUMN_ALIASES.include?(header.to_s.strip.downcase) }
    end

    def failure(message)
      Result.new(success: false, rows: [], errors: [ message ])
    end
  end
end
