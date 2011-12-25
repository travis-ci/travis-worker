source :rubygems

gem 'travis-build',     :git => 'git://github.com/travis-ci/travis-build.git'
gem 'travis-support',   :git => 'git://github.com/travis-ci/travis-support.git'

gem 'vagrant',          '~> 0.8.10'
gem 'thor',             '~> 0.14.6'

gem 'faraday',          '~> 0.7.5'
gem 'simple_states',    '~> 0.1.0.pre2'
gem 'hashr',            '~> 0.0.18'
gem 'multi_json',       '~> 1.0.4'
gem 'json'

platform :jruby do
  gem 'hot_bunnies',    '~> 1.3.3'
  gem 'net-ssh-shell',  '~> 0.2.0'
  gem 'jruby-openssl',  '~> 0.7.4'
end

group :test do
  gem 'rake',           '~> 0.9.2'
  gem 'mocha'
  gem 'rspec'
  gem 'simplecov',      '>= 0.4.0', :require => false
end

