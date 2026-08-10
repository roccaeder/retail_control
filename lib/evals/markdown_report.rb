module Evals
  # Renders Runner results as a markdown table, ready to paste into the README.
  class MarkdownReport
    HEADER = "| Strategy | Cases | Precision | Recall | Recall@3 | Auto-match rate | False auto-match rate | Unmatched rate | Mean latency (ms) |"
    DIVIDER = "|---|---|---|---|---|---|---|---|---|"

    def self.render(results) = new(results).render

    def initialize(results)
      @results = results
    end

    def render
      ([ HEADER, DIVIDER ] + results.map { |r| row(r) }).join("\n")
    end

    private

    attr_reader :results

    def row(r)
      [
        r.strategy, r.total_cases,
        pct(r.precision), pct(r.recall), pct(r.recall_at_3),
        pct(r.auto_match_rate), pct(r.false_auto_match_rate), pct(r.unmatched_rate),
        r.mean_latency_ms
      ].then { |cols| "| #{cols.join(' | ')} |" }
    end

    def pct(value) = "#{(value * 100).round(1)}%"
  end
end
