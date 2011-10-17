source :rubygems

gem 'travis-build', :git => 'git://github.com/travis-ci/travis-build.git'

gem 'vagrant',       '~> 0.8.0'
gem 'net-ssh-shell', '~> 0.2.0'
gem 'faraday'

gem 'simple_states'
gem 'hashr',         '~> 0.0.13'
gem 'multi_json'
gem 'json'

gem 'rake',          '~> 0.9.2'
gem 'thor'

platform :jruby do
  gem 'jruby-openssl'
  gem 'hot_bunnies', '>= 1.2.1'
end

platform :ruby do
  gem 'god'
end

group :development do
  gem 'yard', '~> 0.7.1'

  platform :ruby do
    gem 'rdiscount'
  end
end

group :test do
  gem 'mocha'
  gem 'rspec'

  platforms :ruby_18 do
    gem 'minitest'
    gem 'minitest_tu_shim'
  end
end

gem 'simplecov', '>= 0.4.0', :require => false, :group => :test
