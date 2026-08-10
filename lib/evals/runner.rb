module Evals
  # Runs every strategy in Matching::Strategies::REGISTRY (or an explicit
  # list, for the regression test) against the golden dataset and reports
  # precision/recall/etc per strategy, individually — this measures each
  # strategy in isolation, not Matching::ResolveRowService's combined
  # decision, so a future LLM strategy can be compared apples-to-apples
  # against exact/normalized/trigram on the exact same cases.
  #
  # Builds the golden catalog as real Product records (strategies query the
  # database) inside a transaction that's always rolled back, so nothing
  # persists past a single run.
  class Runner
    Metrics = Data.define(
      :strategy, :total_cases, :positive_cases,
      :precision, :recall, :recall_at_3,
      :auto_match_rate, :false_auto_match_rate, :unmatched_rate,
      :mean_latency_ms
    )

    def self.run(strategies: Matching::Strategies::REGISTRY) = new(strategies:).run

    def initialize(strategies:)
      @strategies = strategies
      @dataset = GoldenDataset.load
    end

    def run
      results = nil

      ActiveRecord::Base.transaction do
        account = Account.create!(name: "Eval harness", subdomain: "eval-harness-#{SecureRandom.hex(4)}")

        ActsAsTenant.with_tenant(account) do
          dataset.catalog.each { |name| Product.create!(account:, name:, stock: 0) }
          results = strategies.map { |strategy| evaluate(strategy) }
        end

        raise ActiveRecord::Rollback
      end

      results
    end

    private

    attr_reader :strategies, :dataset

    def evaluate(strategy)
      outcomes = dataset.cases.map { |kase| evaluate_case(strategy, kase) }

      positive = outcomes.select { |o| o[:expected] }
      proposed = outcomes.select { |o| o[:top] }

      Metrics.new(
        strategy: strategy.name.demodulize,
        total_cases: outcomes.size,
        positive_cases: positive.size,
        precision: rate(proposed.count { |o| o[:correct] }, proposed.size),
        recall: rate(positive.count { |o| o[:correct] }, positive.size),
        recall_at_3: rate(positive.count { |o| o[:in_top3] }, positive.size),
        auto_match_rate: rate(proposed.size, outcomes.size),
        false_auto_match_rate: rate(proposed.count { |o| !o[:correct] }, proposed.size),
        unmatched_rate: rate(outcomes.size - proposed.size, outcomes.size),
        mean_latency_ms: mean(outcomes.map { |o| o[:latency_ms] })
      )
    end

    def evaluate_case(strategy, kase)
      normalized_name = Matching::Normalizer.call(kase.input)

      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      candidates = strategy.call(raw_name: kase.input, normalized_name:)
      latency_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000

      top = candidates.first
      top3_names = candidates.first(3).map { |c| c.product.name }

      {
        expected: kase.expected,
        top:,
        correct: top && top.product.name == kase.expected,
        in_top3: kase.expected.present? && top3_names.include?(kase.expected),
        latency_ms:
      }
    end

    def rate(numerator, denominator)
      return 0.0 if denominator.zero?
      (numerator.to_f / denominator).round(4)
    end

    def mean(values)
      return 0.0 if values.empty?
      (values.sum / values.size).round(3)
    end
  end
end
