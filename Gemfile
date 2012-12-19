source :rubygems

# Use local clones if possible.
# If you want to use your local copy, just symlink it to vendor.
def local_or_remote_gem(name, options = Hash.new)
  local_path = File.expand_path("../vendor/#{name}", __FILE__)
  if File.exist?(local_path)
    gem name, options.merge(:path => local_path).delete_if { |key, _| [:git, :branch].include?(key) }
  else
    gem name, options
  end
end

local_or_remote_gem 'travis-build',     :git => 'https://github.com/travis-ci/travis-build'
local_or_remote_gem 'travis-support',   :git => 'https://github.com/travis-ci/travis-support'

gem 'vagrant',          :git => 'https://github.com/joshk/vagrant', :branch => '1-0-stable'
gem 'vagrant-vbguest'

gem 'thor',             '~> 0.14.6'

gem 'faraday',          '~> 0.7.5'
gem 'simple_states',    '0.1.0.pre2'
gem 'hashr',            '~> 0.0.18'
gem 'multi_json',       '~> 1.2.0'
gem 'json'

platform :jruby do
  gem 'hot_bunnies',    '~> 1.4.0'
  gem 'net-ssh-shell',  :git => 'git://github.com/joshk/net-ssh-shell'
  gem 'jruby-openssl',  '~> 0.7.4'
end

group :test do
  gem 'rake',           '~> 0.9.2'
  gem 'mocha',          '~> 0.11.0'
  gem 'rspec'
  gem 'simplecov',      '>= 0.4.0', :require => false
end

