require "test_helper"

class Evals::MarkdownReportTest < ActiveSupport::TestCase
  test "renderiza una tabla markdown con una fila por estrategia" do
    results = [
      Evals::Runner::Metrics.new(
        strategy: "Exact", total_cases: 200, positive_cases: 180,
        precision: 1.0, recall: 0.344, recall_at_3: 0.344,
        auto_match_rate: 0.31, false_auto_match_rate: 0.0, unmatched_rate: 0.69,
        mean_latency_ms: 1.582
      ),
      Evals::Runner::Metrics.new(
        strategy: "Trigram", total_cases: 200, positive_cases: 180,
        precision: 0.9, recall: 1.0, recall_at_3: 1.0,
        auto_match_rate: 1.0, false_auto_match_rate: 0.1, unmatched_rate: 0.0,
        mean_latency_ms: 2.518
      )
    ]

    report = Evals::MarkdownReport.render(results)
    lines = report.lines.map(&:chomp)

    assert_equal 4, lines.size
    assert_match(/\| Strategy \|/, lines[0])
    assert_match(/^\|---/, lines[1])
    assert_match(/\| Exact \| 200 \| 100.0% \| 34.4% \| 34.4% \| 31.0% \| 0.0% \| 69.0% \| 1.582 \|/, lines[2])
    assert_match(/\| Trigram \| 200 \| 90.0% \| 100.0% \| 100.0% \| 100.0% \| 10.0% \| 0.0% \| 2.518 \|/, lines[3])
  end

  test "una lista vacía de resultados renderiza solo el encabezado" do
    report = Evals::MarkdownReport.render([])
    assert_equal 2, report.lines.size
  end
end
