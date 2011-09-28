source :rubygems

gem 'hashr',         '~> 0.0.13'
gem 'multi_json'
gem 'json'

gem 'vagrant',  '~> 0.7.0'

platform :jruby do
  gem 'jruby-openssl'
  gem 'hot_bunnies'
end

gem 'faraday',  '~> 0.7.3'

gem 'net-ssh-shell'

gem 'rake',     '~> 0.9.2'
gem 'thor'

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
  # gem 'web-socket-ruby'
  # gem 'fakeredis'
  # gem 'fakeweb'

  platforms :ruby_18 do
    gem 'minitest'
    gem 'minitest_tu_shim'
  end

  gem "evented-spec", :git => "git://github.com/ruby-amqp/evented-spec.git"
end
