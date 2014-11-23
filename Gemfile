source 'https://rubygems.org'

ruby '1.9.3', engine: 'jruby', engine_version: '1.7.16' if ENV.key?('DYNO')

gem 'travis-build',     git: 'https://github.com/travis-ci/travis-build', ref: 'sf-cache-config-missing'
gem 'travis-support',   git: 'https://github.com/travis-ci/travis-support', ref: 'f1cbac9'

gem 'celluloid',        git: 'https://github.com/celluloid/celluloid', ref: '5a56056'

gem 'activesupport',    '~> 3.2'

gem 'thor'

gem 'faraday',          '~> 0.7.5'
gem 'hashr',            '~> 0.0.18'
gem 'multi_json',       '~> 1.2.0'
gem 'json'
gem 'coder'

# Use my fork until https://github.com/fog/fog/pull/3212 is merged and released
gem 'fog',             git: 'https://github.com/BanzaiMan/fog', branch: 'ha-feature-bluebox-vhs_id'
gem 'travis-saucelabs-api', '~> 0.0'
gem 'docker-api'

gem 'net-ssh',          '~> 2.9.0'
gem 'sshjr',            git: 'https://github.com/joshk/sshjr'

gem 'metriks',          '0.9.9.5'

gem 'march_hare',       '2.2.0'

group :test do
  gem 'rake',           '~> 0.9.2'
  gem 'mocha',          '~> 0.11.0'
  gem 'rspec'
  gem 'simplecov',      '>= 0.4.0', require: false
  gem 'webmock'
end

group :development do
  gem 'pry'
end
