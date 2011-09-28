require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

task 'travis:worker:config' do
  $: << 'lib'
  require 'travis/worker'
  Travis::Worker.init
end

# task 'resque:setup' => 'travis:worker:config'

task :default => :test

