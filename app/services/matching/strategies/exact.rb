module Matching
  module Strategies
    # Case-insensitive literal match against the raw supplier input, before
    # any unit/accent normalization. Catches suppliers whose product names
    # already match the catalog almost byte-for-byte.
    class Exact < Base
      def call
        Product.where("name ILIKE ?", raw_name.to_s.strip)
               .map { |product| Candidate.new(product:, score: 1.0, strategy: :exact) }
      end
    end
  end
end
