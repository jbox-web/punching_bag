# frozen_string_literal: true

require 'simplecov'
require 'simplecov_json_formatter'

# Start SimpleCov before any measured code is required, so line-level and
# branch-level execution during load (class bodies, engine initializers) is
# tracked. Starting it after Combustion boots the engine would miss them.
SimpleCov.start do
  enable_coverage :branch
  formatter SimpleCov::Formatter::MultiFormatter.new([SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::JSONFormatter])
  skip 'spec/'
end

require 'combustion'

# Load before Combustion boots ActiveRecord so PunchingBag's engine initializer
# detects ActsAsTaggableOn and wires the tag-trending integration.
require 'acts-as-taggable-on'

Combustion.path = 'spec/dummy'
Combustion.initialize! :active_record

require 'rspec/rails'
require 'rspec/its'

RSpec.configure do |config|
  config.color = true
  config.fail_fast = false

  config.order = :random
  Kernel.srand config.seed

  # disable monkey patching
  # see: https://relishapp.com/rspec/rspec-core/v/3-8/docs/configuration/zero-monkey-patching-mode
  config.disable_monkey_patching!

  config.use_transactional_fixtures = true
end
