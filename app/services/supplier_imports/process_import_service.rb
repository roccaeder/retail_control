module SupplierImports
  # Orchestrates one SupplierImport end to end: parse the attached file,
  # resolve each row against the catalog, persist a Resolution per row,
  # and roll up counts onto the SupplierImport. Called from
  # SupplierImportJob, but plain enough to call synchronously in tests.
  class ProcessImportService
    Result = Data.define(:success, :supplier_import, :errors)

    def self.call(supplier_import:) = new(supplier_import:).call

    def initialize(supplier_import:)
      @supplier_import = supplier_import
    end

    def call
      supplier_import.update!(status: :processing)

      parse_result = ParseFileService.call(supplier_import:)
      return fail_import(parse_result.errors) unless parse_result.success

      counts = Hash.new(0)
      parse_result.rows.each do |row|
        status = persist_resolution(row)
        counts[status] += 1 if status
      end

      supplier_import.update!(
        status: :completed,
        total_rows: parse_result.rows.size,
        auto_matched_count: counts["auto_matched"],
        needs_review_count: counts["needs_review"],
        unmatched_count: counts["unmatched"]
      )

      Result.new(success: true, supplier_import:, errors: [])
    rescue => e
      fail_import([ e.message ])
    end

    private

    attr_reader :supplier_import

    # Isolated per row: a single bad row (unexpected DB error, odd
    # encoding, ...) is logged and skipped rather than failing the whole
    # batch — the rest of the supplier's price list still gets processed.
    def persist_resolution(row)
      decision = Matching::ResolveRowService.call(raw_name: row.raw_name)

      resolution = Resolution.create!(
        account:,
        supplier_import:,
        product: decision.product,
        raw_row: row.raw_row,
        raw_name: row.raw_name,
        normalized_name: Matching::Normalizer.call(row.raw_name),
        strategy: decision.strategy,
        score: decision.score,
        candidates: decision.candidates,
        status: decision.status
      )
      resolution.status
    rescue => e
      Rails.logger.error("SupplierImports::ProcessImportService: failed to persist row #{row.raw_name.inspect}: #{e.message}")
      nil
    end

    def account = supplier_import.account

    def fail_import(errors)
      supplier_import.update!(status: :failed, error_message: errors.join("; "))
      Result.new(success: false, supplier_import:, errors:)
    end
  end
end
