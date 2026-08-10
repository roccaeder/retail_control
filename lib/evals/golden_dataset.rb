module Evals
  # Loads the versioned, hand-labeled dataset (test/fixtures/evals/supplier_products.yml)
  # used both by `rake evals:run` and by the CI regression test, so both
  # always evaluate against the exact same labeled data.
  class GoldenDataset
    FIXTURE_PATH = Rails.root.join("test/fixtures/evals/supplier_products.yml")

    Case = Data.define(:input, :expected)
    Dataset = Data.define(:catalog, :cases)

    def self.load = new.load

    def load
      data = YAML.safe_load_file(FIXTURE_PATH)
      catalog = data.fetch("catalog").map { |row| row.fetch("name") }
      cases = data.fetch("cases").map { |row| Case.new(input: row.fetch("input"), expected: row["expected"]) }
      Dataset.new(catalog:, cases:)
    end
  end
end
