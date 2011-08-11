source :rubygems
gem 'resque',              '~> 1.17.0'
gem 'resque-meta',         '~> 1.0.3'
gem 'resque-heartbeat',    '~> 0.0.2'

platforms :ruby_18 do
  gem 'SystemTimer'
end

gem 'vagrant',       "0.7.7"
# gem 'vagrant',      :git => 'git://github.com/mitchellh/vagrant.git'
# gem 'vagrant',       "~>  0.8.2"

gem 'net-ssh'
gem 'net-ssh-shell', '~> 0.2.0'
gem 'hashr',         '~> 0.0.9'
gem "multi_json"

# amqp migration is a work in progress but it does not affect resque-based worker in any way
gem "amqp",         :git => "git://github.com/ruby-amqp/amqp.git"
gem "amq-client",   :git => "git://github.com/ruby-amqp/amq-client.git"
gem "amq-protocol", :git => "git://github.com/ruby-amqp/amq-protocol.git"
gem "eventmachine", :git => "git://github.com/eventmachine/eventmachine.git"

gem 'faraday', '~> 0.7.3'
gem 'rake', '~> 0.9.2'
gem 'thor'
gem 'god'

group :development do
  gem 'yard', '~> 0.7.1'
  gem 'rdiscount'

  gem 'ruby-debug',   :platforms => :mri_18
  gem 'ruby-debug19', :platforms => :mri_19
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
