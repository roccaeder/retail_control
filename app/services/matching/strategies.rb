module Matching
  module Strategies
    # Every strategy the resolver (and the eval harness) runs, in order.
    # Add a new strategy (e.g. Matching::Strategies::Llm) here and both
    # pick it up automatically.
    REGISTRY = [ Exact, Normalized, Trigram ].freeze
  end
end
