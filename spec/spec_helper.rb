$:.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'rubygems'
require "bundler/setup"

require 'rspec'
require 'mocha'

require 'travis/worker'

FIXTURES = {}
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| load f}

include Travis::Worker

RSpec.configure do |config|
  config.mock_with :mocha
end

