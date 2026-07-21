# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`punching_bag` is a Rails engine gem that tracks hits on any model and computes simple trending. A host app calls `acts_as_punchable` on a model, then `record.punch(request)` in a controller. Hits accumulate as `Punch` rows; a rake task later compresses old rows for performance.

## Commands

- `bin/rspec` — run the full suite (Combustion boots the `spec/dummy` app against SQLite).
- `bin/rspec spec/models/punch_spec.rb` — one file. Append `:42` for a single example at that line.
- `bin/rubocop` — lint (RuboCop + performance/rake/rspec plugins; config in `.rubocop.yml`).
- `bin/guard` — watch mode (re-runs specs on file change, see `Guardfile`).

### Multi-Rails testing (Appraisal)

CI runs the suite against Rails 7.2 / 8.0 / 8.1 via the generated bundles in `gemfiles/`:

- `BUNDLE_GEMFILE=gemfiles/rails_8.1.gemfile bin/rspec` — run against a specific Rails.
- Edit `Appraisals`, then `bin/appraisal install` to regenerate `gemfiles/*.gemfile`. Never hand-edit the generated gemfiles.

## Architecture

Loading is Zeitwerk (`lib/punching_bag.rb`), with `lib/generators` ignored (generators are loaded by Rails on demand, not eager-loaded).

The mixin is installed in three hops, worth tracing when following how `acts_as_punchable` reaches a model:

1. `PunchingBag::Engine` (`engine.rb`) runs on `active_record` load and does `ActiveRecord::Base.extend(PunchingBag::Macros)`, plus wires the ActsAsTaggableOn integration **only if `::ActsAsTaggableOn` is already defined**.
2. `PunchingBag::Macros#acts_as_punchable` (called in a host model) extends `ActiveRecord::ClassMethods`, includes `ActiveRecord::InstanceMethods`, and declares `has_many :punches, as: :punchable`.
3. `PunchingBag::ActiveRecord` then provides `most_hit` / `sort_by_popularity` (class) and `hits` / `punch` (instance).

`PunchingBag` module methods (`punch`, `average_time`, `combine_punches`, `combine`) hold the engine-level logic; the `Punch` model holds the per-row combining rules.

### The Punch model and the combining domain

`Punch` is polymorphic (`punchable_id` + `punchable_type`) and carries `starts_at`, `ends_at`, `average_time`, `hits`. The vocabulary drives the whole compression scheme — keep it straight:

- **jab** = a punch with exactly 1 hit; **combo** = a punch aggregating >1 hits.
- `timeframe` is inferred from the span between `starts_at` and `ends_at` (`:second` → `:hour` → `:day` → `:month` → `:year`).
- `combine_punches` (invoked by the `punching_bag:combine` rake task) walks every punchable and folds old punches into coarser combos: year, then month, then day, then hour. Each `combine_by_*` guards against folding a punch that is already a combo at a coarser timeframe, so aggregation only ever moves finer→coarser.
- `combine_with` merges one punch into a combo, recomputing the weighted `average_time` via `PunchingBag.average_time`, summing `hits`, widening the `starts_at`/`ends_at` span, and destroying the absorbed row.

Bot filtering: `PunchingBag.punch` returns `false` without recording when `request.bot?` is truthy (via the `voight_kampff` dependency). Passing no `request` means bots are counted.

### ActsAsTaggableOn integration

`acts_as_taggable_on.rb` adds `most_hit` / `hits` to `ActsAsTaggableOn::Tag` by raw-SQL-joining `taggings` to `punches` on the shared polymorphic key. It is only active when the host app has ActsAsTaggableOn loaded (guarded in the engine initializer).

### Generator

`rails g punching_bag` (`lib/generators/punching_bag/`) copies the `create_punches_table` migration. `next_migration_number` sleeps 1s to guarantee unique timestamps.

## Test setup notes

`spec/spec_helper.rb` uses Combustion with only `:active_record`. The throwaway host lives in `spec/dummy/` (`Article` model = `acts_as_punchable`, schema in `spec/dummy/db/schema.rb`). SimpleCov emits `coverage/coverage.json`, which CI uploads to Qlty.
