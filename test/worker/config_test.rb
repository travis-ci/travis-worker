# require 'test_helper'
#
# class WorkerConfigTest < Test::Unit::TestCase
#   include Travis
#
#   test 'redis.url defaults to ENV["REDIS_URL"]' do
#     ENV['REDIS_URL'] = 'redis/url'
#     assert_equal 'redis/url', Travis::Worker::Config.new.redis.url
#   end
# end
