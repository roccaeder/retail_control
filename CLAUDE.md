# retail_control

Rails 8 ERP for small retail shops in Peru. Multi-tenant via acts_as_tenant.

## CRITICAL: everything runs in Docker

Ruby, Rails and Postgres all live inside containers. There is **no local
Ruby, no local Rails, no local Postgres** on the host machine.

Never run `bin/rails`, `bundle`, `rake` or `psql` directly. Every command
must be prefixed with `docker compose exec app`.

The stack is started with `docker compose up`. Assume it is already
running. If a command fails with "connection refused" or "no such
service", tell me instead of trying to start things yourself.

## Commands

```bash
# Rails console / generic rails commands
docker compose exec app bin/rails console
docker compose exec app bin/rails db:migrate
docker compose exec app bin/rails g migration AddFooToBar

# Tests (Minitest)
docker compose exec app bin/rails test
docker compose exec app bin/rails test test/services/matching/normalizer_test.rb

# Rake tasks
docker compose exec app bin/rails evals:run

# Postgres
docker compose exec db psql -U postgres -d retail_control_development
```

## Adding a gem

Editing the Gemfile is not enough — the image must be rebuilt:

```bash
# 1. edit Gemfile
docker compose exec app bundle install   # updates Gemfile.lock
docker compose build app                 # bakes gems into the image
docker compose up -d app                 # restart with the new image
```

Always tell me when a change requires a rebuild.

## Conventions

- **Tests: Minitest** + FactoryBot + shoulda-matchers. Not RSpec.
- SimpleCov gates at 75% line / 60% branch — keep it green on every commit.
- Business logic goes in service objects: `app/services/<Namespace>/<Verb>Service.rb`
- Service shape: `Result = Data.define(:success, :thing, :errors)`,
  class-level `.call(**kwargs)` delegating to instance `#call`, wrapped in
  `ActiveRecord::Base.transaction`, rescuing `RecordInvalid`.
- Controllers stay thin: params + redirect.
- Every model is tenant-scoped with `acts_as_tenant(:account)`.
- Code, comments and commit messages in English.
- Small, reviewable commits. One concern per commit.

## Gotchas

- Files created by the container may be owned by root on the host.
- Solid Queue is the Active Job adapter. No Redis, no Sidekiq.
- Postgres 16. pg_trgm needs `enable_extension` in a migration.