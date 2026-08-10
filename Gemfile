source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# --- Frontend (The "No-Node" Stack) ---
gem "importmap-rails"      # El motor que reemplaza a Node/Yarn
gem "turbo-rails"          # SPA-like speed
gem "stimulus-rails"       # El framework JS modesto
gem "tailwindcss-rails"    # Tailwind compilado en Rust (sin Node)
gem "propshaft"            # Asset pipeline moderno y simple
gem "lucide-rails"         # Iconos

# --- ERP & Auth ---
gem "devise"
gem "avo"
gem "acts_as_tenant"

# --- Backend & Performance ---
gem "pagy", "~> 43.5"
gem "jbuilder"
gem "csv" # no longer a default gem as of Ruby 3.4
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "image_processing", "~> 2.0"

# --- Deployment ---
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "simplecov",        require: false
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "webmock"
end
