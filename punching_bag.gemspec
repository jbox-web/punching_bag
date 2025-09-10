# frozen_string_literal: true

require_relative 'lib/punching_bag/version'

Gem::Specification.new do |s|
  s.name         = 'punching_bag'
  s.version      = PunchingBag::VERSION::STRING
  s.platform     = Gem::Platform::RUBY
  s.author       = 'Adam Crownoble'
  s.email        = 'adam@codenoble.com'
  s.homepage     = 'https://github.com/biola/punching_bag'
  s.summary      = 'PunchingBag hit conter and trending plugin'
  s.description  = 'PunchingBag is a hit counting and simple trending engine for Ruby on Rails'
  s.license      = 'MIT'

  s.required_ruby_version = '>= 3.2.0'

  s.files = Dir['LICENSE', 'app/**/*.rb', 'lib/**/*.rb', 'lib/tasks/*.rake']

  s.add_dependency 'logger'
  s.add_dependency 'rails', '>= 7.1'
  s.add_dependency 'voight_kampff', '>= 1.0'
  s.add_dependency 'zeitwerk'
end
