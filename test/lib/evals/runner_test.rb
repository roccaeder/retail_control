require "test_helper"

# Regression guard: fails if a change to the normalizer, a strategy, or the
# golden dataset itself makes matching quality worse. Baselines below were
# captured from an actual `rake evals:run` against
# test/fixtures/evals/supplier_products.yml (200 cases), with a small
# margin so the test isn't flaky. Update deliberately — with a comment
# explaining why — when the dataset or strategies change on purpose.
class Evals::RunnerTest < ActiveSupport::TestCase
  class SilentStrategy < Matching::Strategies::Base
    def call = []
  end

  test "estrategias determinísticas (exact/normalized) nunca proponen un match incorrecto" do
    results = Evals::Runner.run.index_by(&:strategy)

    assert_equal 1.0, results.fetch("Exact").precision
    assert_equal 1.0, results.fetch("Normalized").precision
  end

  test "recall no regresa por debajo del baseline registrado" do
    results = Evals::Runner.run.index_by(&:strategy)

    assert results.fetch("Exact").recall >= 0.30, "Exact recall regresó: #{results['Exact'].recall}"
    assert results.fetch("Normalized").recall >= 0.70, "Normalized recall regresó: #{results['Normalized'].recall}"
    assert results.fetch("Trigram").recall >= 0.95, "Trigram recall regresó: #{results['Trigram'].recall}"
    assert results.fetch("Trigram").recall_at_3 >= 0.95, "Trigram recall@3 regresó: #{results['Trigram'].recall_at_3}"
  end

  test "false_auto_match_rate del trigram no empeora (razón por la que nunca auto-matchea)" do
    trigram = Evals::Runner.run.index_by(&:strategy).fetch("Trigram")
    assert trigram.false_auto_match_rate <= 0.15, "Trigram false_auto_match_rate empeoró: #{trigram.false_auto_match_rate}"
  end

  test "no persiste el catálogo golden fuera de la corrida" do
    assert_no_difference -> { Account.count } do
      Evals::Runner.run
    end
  end

  test "corre solo las estrategias indicadas, no todo REGISTRY" do
    results = Evals::Runner.run(strategies: [ Matching::Strategies::Exact ])
    assert_equal [ "Exact" ], results.map(&:strategy)
  end

  test "no explota (división por cero) cuando una estrategia nunca propone candidatos" do
    result = Evals::Runner.run(strategies: [ SilentStrategy ]).first

    assert_equal 0.0, result.precision
    assert_equal 0.0, result.auto_match_rate
    assert_equal 0.0, result.false_auto_match_rate
    assert_equal 1.0, result.unmatched_rate
  end
end
