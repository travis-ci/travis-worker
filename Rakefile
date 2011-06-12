require 'rake'
require 'rake/testtask'
require 'resque/tasks'

Rake::TestTask.new do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

task 'travis:worker:config' do
  $: << 'lib'
  require 'travis/worker'
  Resque.redis = ENV['REDIS_URL'] = Travis::Worker.config.redis.url
end

task 'resque:setup' => 'travis:worker:config'

task :default => :test

