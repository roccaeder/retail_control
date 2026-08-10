module Matching
  # Runs every registered strategy for one supplier row and decides what to
  # do with the result. Doesn't touch the database beyond reading the
  # catalog (via the strategies) — persisting a Resolution is the caller's
  # job, this just returns a Decision.
  class ResolveRowService
    Decision = Data.define(:status, :product, :strategy, :score, :candidates)

    CANDIDATE_LIMIT = 5

    # Only these strategies are trusted to auto-match without a human.
    # Trigram (and any future fuzzy/LLM strategy) always lands in
    # needs_review, however high its score — we have no labeled data yet
    # to justify an auto-match threshold for it. See the eval harness.
    AUTO_MATCH_STRATEGIES = %i[exact normalized].freeze

    def self.call(raw_name:) = new(raw_name:).call

    def initialize(raw_name:)
      @raw_name = raw_name
      @normalized_name = Normalizer.call(raw_name)
    end

    def call
      ranked = rank(dedupe(collect_candidates))
      winner = ranked.first

      if winner && AUTO_MATCH_STRATEGIES.include?(winner.strategy)
        decision(status: :auto_matched, winner:, ranked:)
      elsif winner
        decision(status: :needs_review, winner: nil, ranked:)
      else
        decision(status: :unmatched, winner: nil, ranked: [])
      end
    end

    private

    attr_reader :raw_name, :normalized_name

    def collect_candidates
      Strategies::REGISTRY.flat_map { |strategy| strategy.call(raw_name:, normalized_name:) }
    end

    # The same product can surface from more than one strategy (an exact
    # match is trivially also a perfect trigram match). Keep one entry per
    # product so the candidates list reflects distinct products, not
    # duplicate sightings of the same one.
    def dedupe(candidates)
      candidates.group_by { |c| c.product.id }.values.map { |group| best_of(group) }
    end

    def best_of(group)
      group.min_by { |c| [ -c.score, strategy_priority(c.strategy) ] }
    end

    def rank(candidates)
      candidates.sort_by { |c| [ -c.score, strategy_priority(c.strategy) ] }
    end

    def strategy_priority(strategy)
      STRATEGY_PRIORITY.fetch(strategy)
    end

    STRATEGY_PRIORITY = Strategies::REGISTRY.each_with_index.to_h { |klass, i| [ klass.name.demodulize.underscore.to_sym, i ] }

    def decision(status:, winner:, ranked:)
      Decision.new(
        status:,
        product: winner&.product,
        strategy: winner&.strategy,
        score: winner&.score,
        candidates: ranked.first(CANDIDATE_LIMIT).map { |c| serialize(c) }
      )
    end

    def serialize(candidate)
      { "product_id" => candidate.product.id, "score" => candidate.score, "strategy" => candidate.strategy.to_s }
    end
  end
end
