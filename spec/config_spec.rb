require 'spec_helper'

describe Travis::Worker::Config do
  before(:each) do
    Travis::Worker::Config.send :public, *Travis::Worker::Config.protected_instance_methods
    Travis::Worker::Config.any_instance.stubs(:read_yml).returns({})
    File.stubs(:exists?).returns(true)
  end

  let(:config) { Travis::Worker::Config.new }

  it "looks for a file ./config/worker.yml" do
    File.stubs(:exists?).with('./config/worker.yml').returns(true)
    config.path.should eql './config/worker.yml'
  end

  it "looks for a file ~/.worker.yml" do
    File.stubs(:exists?).with('./config/worker.yml').returns(false)
    File.stubs(:exists?).with('~/.worker.yml').returns(true)
    config.path.should eql '~/.worker.yml'
  end

  it "reads ./config/worker.yml first, ./config/worker.[env].yml second and merges them" do
    File.stubs(:exists?).with('./config/worker.yml').returns(true)

    Travis::Worker::Config.any_instance.stubs(:read_yml).
      with('./config/worker.yml').
      returns('env' => 'staging', 'staging' => { 'foo' => 'local', 'bar' => 'local' })
    Travis::Worker::Config.any_instance.stubs(:read_yml).
      with('./config/worker.staging.yml').
      returns('bar' => 'env', "baz" => "env")

    merged = config.read
    merged['env'].should eql 'staging'
    merged['foo'].should eql 'local'
    merged['bar'].should eql 'local'
    merged['baz'].should eql 'env'
  end

  it 'name returns the first part of the host name' do
    Socket.stubs(:gethostname).returns('test-1.worker.travis-ci.org')
    config.name.should == 'test-1'
  end

  it 'host return the machine hostname' do
    Socket.stubs(:gethostname).returns('test-1.worker.travis-ci.org')
    config.host.should == 'test-1.worker.travis-ci.org'
  end

  it 'names returns the vm names' do
    Travis::Worker::VirtualMachine.stubs(:provider => stub(:vm_names => %w(worker-1)))
    config.names.should == %w(worker-1)
  end

  it 'vms includes the Vms module' do
    Travis::Worker::Config.any_instance.stubs(:read_yml).returns({ 'vms' => { 'count' => 5 } })
    config.vms.meta_class.included_modules.include?(Travis::Worker::Config::Vms).should be_true
    config.vms.count.should eql 5
  end

  describe :defaults do
    it 'before_script timeout defaults to 300' do
      config.timeouts.before_script.should == 300
    end

    it 'after_script timeout defaults to 300' do
      config.timeouts.after_script.should == 300
    end

    it 'after_success timeout defaults to 300' do
      config.timeouts.after_success.should == 300
    end

    it 'after_failure timeout defaults to 300' do
      config.timeouts.after_failure.should == 300
    end

    it 'script timeout defaults to 600' do
      config.timeouts.script.should == 600
    end

    it 'bundle timeout defaults to 300' do
      config.timeouts.install.should == 300
    end

    it 'default timeout is 180' do
      config.timeouts.default.should == 180
    end

    it 'queue defaults to builds' do
      config.queue.should == 'builds.common'
    end

    it 'vms.count defaults to 1' do
      config.vms.count.should == 1
    end

    it 'vms.names defaults to [travis-env-1]' do
      Travis::Worker.config.env = 'test' # hrmm
      config.vms.count = 2
      config.vms.names.should == %w(travis-test-1 travis-test-2)
    end

    it 'vms.recipes? defaults to false' do
      config.vms.recipes?.should be_false
    end
  end

  describe 'set' do
    it 'sets a value to a dot-separated path' do
      config.set('foo.bar', 'baz' => 'buz')
      config.foo.bar.baz.should == 'buz'
    end
  end
end
