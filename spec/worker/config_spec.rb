# require 'spec_helper'
# 
# describe Travis::Worker do
#   include Travis::Worker
#   before(:each) do
#     Config.send :public, *Config.protected_instance_methods
#     Config.any_instance.stubs(:read_yml).returns({})
#     File.stubs(:exists?).returns(true)
#   end
# 
#   let(:config) { Config.new }
# 
#   it "looks for a file ./config/worker.yml" do
#     File.stubs(:exists?).with('./config/worker.yml').returns(true)
#     config.path.should eql './config/worker.yml'
#   end
# 
#   it "looks for a file ~/.worker.yml" do
#     File.stubs(:exists?).with('./config/worker.yml').returns(false)
#     File.stubs(:exists?).with('~/.worker.yml').returns(true)
#     config.path.should eql '~/.worker.yml'
#   end
# 
#   it "reads ./config/worker.yml first, ./config/worker.[env].yml second and merges them" do
#     File.stubs(:exists?).with('./config/worker.yml').returns(true)
# 
#     Config.any_instance.stubs(:read_yml).with('./config/worker.yml').returns('env' => 'staging', 'staging' => { 'foo' => 'foo' })
#     Config.any_instance.stubs(:read_yml).with('./config/worker.staging.yml').returns('bar' => 'bar')
# 
#     config.read['env'].should eql 'staging'
#     config.read['foo'].should eql 'foo'
#     config.read['bar'].should eql 'bar'
#   end
# 
#   it 'vms includes the Vms module' do
#     Config.any_instance.stubs(:read_yml).returns({ 'vms' => { 'count' => 5 } })
#     config.vms.meta_class.included_modules.include?(Config::Vms).should be_true
#     config.vms.count.should eql 5
#   end
# 
#   context :defaults do
#     it 'before_script timeout defaults to 120' do
#       config.timeouts.before_script.should eql 120
#     end
# 
#     it 'after_script timeout defaults to 120' do
#       config.timeouts.after_script.should eql 120
#     end
# 
#     it 'script timeout defaults to 600' do
#       config.timeouts.script.should eql 600
#     end
# 
#     it 'bundle timeout defaults to 300' do
#       config.timeouts.bundle.should eql 300
#     end
# 
#     it 'queue defaults to builds' do
#       config.queue.should eql 'builds'
#     end
# 
#     it 'vms.count defaults to 1' do
#       config.vms.count.should eql 1
#     end
# 
#     it 'vms.names defaults to [base, worker-1]' do
#       config.vms.names.should eql %w(base worker-1)
#     end
# 
#     it 'vms.recipes? defaults to false' do
#       config.vms.recipes?.should be_false
#     end
# 
# 
#   end
# 
# 
# 
# end
