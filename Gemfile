source 'https://rubygems.org'

gem 'travis-build',     :git => 'https://github.com/travis-ci/travis-build'
gem 'travis-support',   :git => 'https://github.com/travis-ci/travis-support'

gem 'celluloid',        :git => 'https://github.com/celluloid/celluloid', :ref => '8a8d925'

gem 'vagrant',          :git => 'https://github.com/joshk/vagrant', :branch => '1-0-stable'
gem 'vagrant-vbguest'

gem 'activesupport'

gem 'thor',             '~> 0.14.6'

gem 'faraday',          '~> 0.7.5'
gem 'hashr',            '~> 0.0.18'
gem 'multi_json',       '~> 1.2.0'
gem 'json'

gem 'fog',                  :git => 'http://github.com/travis-ci/fog'
gem 'travis-saucelabs-api', '~> 0.0'
gem 'docker-api',           :git => 'http://github.com/joshk/docker-api'

gem 'excon',            '~> 0.25.1'

gem 'net-ssh',          '~> 2.6.8'
gem 'sshjr',            :git => 'https://github.com/joshk/sshjr'

gem 'metriks'

platform :jruby do
  gem 'march_hare',     '2.0.0.rc3'
  gem 'jruby-openssl',  '~> 0.8.0'
end

group :test do
  gem 'rake',           '~> 0.9.2'
  gem 'mocha',          '~> 0.11.0'
  gem 'rspec'
  gem 'simplecov',      '>= 0.4.0', :require => false
end

