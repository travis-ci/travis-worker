require 'rake'
require 'rspec/core/rake_task'

desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  t.pattern = './spec/**/*_spec.rb'
end

task 'travis:worker:config' do
  $: << 'lib'
  require 'travis/worker'
  Travis::Worker.init
end

# task 'resque:setup' => 'travis:worker:config'

task :default => :spec
task :test => :spec
