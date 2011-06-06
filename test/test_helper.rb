ENV['RAILS_ENV'] ||= 'test'

begin
  require 'ruby-debug'
rescue LoadError => e
  puts e.message
end
require 'bundler/setup'

require 'test/unit'
require 'test_declarative'
require 'mocha'
# require 'fakeredis'
# require 'resque'

require 'travis/worker'

# Dir["#{File.expand_path('../test_helpers/**/*.rb', __FILE__)}"].each do |helper|
#   require helper
# end
#
# class Test::Unit::TestCase
#   include Assertions, TestHelper::Buildable, TestHelper::Redis
#
#   def setup
#     Mocha::Mockery.instance.verify
#     Resque.redis = FakeRedis::Redis.new
#   end
# end
#
