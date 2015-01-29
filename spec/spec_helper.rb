$:.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'rubygems'
require "bundler/setup"

require 'rspec'
require 'mocha'
require 'hashr'
require 'march_hare'
require 'webmock/rspec'

require 'travis/worker'
require 'logger'
require 'stringio'

require 'travis/support'

FIXTURES = {}
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| load f }

include Mocha::API

RSpec.configure do |config|
  config.mock_with :mocha

  config.before(:each) do
    Travis.logger = Logger.new(StringIO.new)
  end

  config.alias_example_to :fit, :focused => true
  config.filter_run :focused => true
  config.run_all_when_everything_filtered = true
end
