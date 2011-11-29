$:.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'rubygems'
require "bundler/setup"

require 'rspec'
require 'mocha'

require 'travis/worker'
require 'travis/support'
require 'logger'
require 'stringio'

FIXTURES = {}
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| load f}

include Mocha::API

RSpec.configure do |config|
  config.mock_with :mocha

  config.before :each do
    Travis.logger = Logger.new(StringIO.new)
  end
end

