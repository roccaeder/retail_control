module Matching
  module Strategies
    # Compares the normalized input against every catalog product name run
    # through the same normalizer, so "500ML" vs "500 ml" or accented vs
    # unaccented spellings match despite the raw strings differing.
    #
    # Products aren't normalized at write time, so this scans the tenant's
    # whole catalog in Ruby. Fine at small-retail-shop scale (dozens to a
    # few hundred products); if the catalog grows large, the next step is a
    # generated/materialized normalized_name column with its own index.
    class Normalized < Base
      def call
        Product.find_each
               .select { |product| Matching::Normalizer.call(product.name) == normalized_name }
               .map { |product| Candidate.new(product:, score: 1.0, strategy: :normalized) }
      end
    end
  end
end
