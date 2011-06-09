source :rubygems
gem 'resque',              '~> 1.17.0'
gem 'resque-meta',         '~> 1.0.3'
gem 'resque-heartbeat'

gem 'vagrant'
gem 'net-ssh'
gem 'net-ssh-shell'
gem 'hashie'
gem 'faraday'

group :development do
  gem "yard", "~> 0.7.1"
  gem "rdiscount"
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

  platforms :mri_18 do
    gem 'ruby-debug'
  end

  platforms :mri_19 do
    gem 'ruby-debug19'
  end
end

