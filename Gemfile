source :rubygems

# Unfortunately this doesn't work with jruby/bundler:
#
#   gem 'travis-build', :git => 'git://github.com/travis-ci/travis-build.git'
#
# It says:
#
# Could not find gem 'travis-build (>= 0) java' in git://github.com/travis-ci/travis-build.git (at master).
# Source does not contain any versions of 'travis-build (>= 0) java'

gem 'travis-build', :path => '../travis-build'

gem 'vagrant',       '~> 0.8.0'
gem 'net-ssh-shell', '~> 0.2.0'
gem 'hashr',         '~> 0.0.13'
gem 'multi_json'
gem 'json'
gem 'rake',          '~> 0.9.2'
gem 'thor'

platform :jruby do
  gem 'jruby-openssl'
  gem 'hot_bunnies', '>= 1.2.0'
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
  gem 'test_declarative'
  gem 'rspec'

  platforms :ruby_18 do
    gem 'minitest'
    gem 'minitest_tu_shim'
  end
end

gem 'simplecov', '>= 0.4.0', :require => false, :group => :test
