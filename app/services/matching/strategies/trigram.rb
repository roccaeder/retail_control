module Matching
  module Strategies
    # Fuzzy match via Postgres pg_trgm similarity() against the catalog,
    # for typos and near-misses that exact/normalized matching can't catch.
    # Always returns the top N candidates regardless of how low the score
    # is — no floor is applied here. Deciding what counts as "close enough"
    # is Matching::ResolveRowService's job, informed by the eval harness.
    class Trigram < Base
      TOP_N = 5

      def call
        quoted_input = Product.connection.quote(normalized_name.to_s)

        Product
          .select("products.*, similarity(lower(products.name), #{quoted_input}) AS trigram_score")
          .order("trigram_score DESC")
          .limit(TOP_N)
          .map { |product| Candidate.new(product:, score: product.trigram_score.to_f, strategy: :trigram) }
      end
    end
  end
end
