module Matching
  module Strategies
    # Common interface every matching strategy implements. A new strategy
    # (e.g. an LLM-backed one) plugs in by subclassing this and adding
    # itself to Matching::Strategies::REGISTRY — nothing else needs to
    # change, including the eval harness.
    class Base
      Candidate = Data.define(:product, :score, :strategy)

      def self.call(raw_name:, normalized_name:) = new(raw_name:, normalized_name:).call

      def initialize(raw_name:, normalized_name:)
        @raw_name = raw_name
        @normalized_name = normalized_name
      end

      # Returns an Array of Candidate, best match first. Empty if nothing found.
      # No score floor is applied here — callers decide what counts as
      # "good enough", strategies just report what they see.
      def call
        raise NotImplementedError
      end

      private

      attr_reader :raw_name, :normalized_name
    end
  end
end
