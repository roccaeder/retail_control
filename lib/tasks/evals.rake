namespace :evals do
  desc "Run matching strategies against the golden dataset and report precision/recall metrics"
  task run: :environment do
    results = Evals::Runner.run
    report = Evals::MarkdownReport.render(results)

    puts report

    output_path = Rails.root.join("tmp/evals_report.md")
    File.write(output_path, report)
    puts "\nWritten to #{output_path.relative_path_from(Rails.root)}"
  end
end
