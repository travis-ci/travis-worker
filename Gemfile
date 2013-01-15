source :rubygems

gem 'travis-build',     git: 'https://github.com/travis-ci/travis-build', branch: 'sf-compile-sh'
gem 'travis-support',   git: 'https://github.com/travis-ci/travis-support'

gem 'celluloid',        :git => 'https://github.com/celluloid/celluloid'

gem 'vagrant',          :git => 'https://github.com/joshk/vagrant', :branch => '1-0-stable'
gem 'vagrant-vbguest'

gem 'thor',             '~> 0.14.6'

gem 'faraday',          '~> 0.7.5'
gem 'simple_states',    '0.1.0.pre2'
gem 'hashr',            '~> 0.0.18'
gem 'multi_json',       '~> 1.2.0'
gem 'json'
gem 'fog'

gem 'metriks'

platform :jruby do
  gem 'hot_bunnies',    '~> 1.4.0'
  gem 'jruby-openssl',  '0.7.4'
end

group :test do
  gem 'rake',           '~> 0.9.2'
  gem 'mocha',          '~> 0.11.0'
  gem 'rspec'
  gem 'simplecov',      '>= 0.4.0', :require => false
end

