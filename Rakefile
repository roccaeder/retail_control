# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

# When running `rake assets:precompile` this is the order of events:
# 1 - Task `avo:yarn_install`
# 2 - Task `avo:sym_link`
# 3 - Cmd  `yarn avo:tailwindcss`
# 4 - Task `assets:precompile`
Rake::Task["assets:precompile"].enhance(["avo:sym_link"])
Rake::Task["avo:sym_link"].enhance(["avo:yarn_install"])
Rake::Task["avo:sym_link"].enhance do
  `yarn avo:tailwindcss`
end

