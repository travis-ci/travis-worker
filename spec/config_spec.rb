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
    expect(config.path).to eql './config/worker.yml'
  end

  it "looks for a file ~/.worker.yml" do
    File.stubs(:exists?).with('./config/worker.yml').returns(false)
    File.stubs(:exists?).with('~/.worker.yml').returns(true)
    expect(config.path).to eql '~/.worker.yml'
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
    expect(merged['env']).to eql 'staging'
    expect(merged['foo']).to eql 'local'
    expect(merged['bar']).to eql 'local'
    expect(merged['baz']).to eql 'env'
  end

  it 'name returns the first part of the host name' do
    Socket.stubs(:gethostname).returns('test-1.worker.travis-ci.org')
    expect(config.name).to eq('test-1')
  end

  it 'host return the machine hostname' do
    Socket.stubs(:gethostname).returns('test-1.worker.travis-ci.org')
    expect(config.host).to eq('test-1.worker.travis-ci.org')
  end

  it 'names returns the vm names' do
    Travis::Worker::VirtualMachine.stubs(:provider => stub(:vm_names => %w(worker-1)))
    expect(config.names).to eq(%w(worker-1))
  end

  it 'vms includes the Vms module' do
    Travis::Worker::Config.any_instance.stubs(:read_yml).returns({ 'vms' => { 'count' => 5 } })
    expect(config.vms.meta_class.included_modules.include?(Travis::Worker::Config::Vms)).to eq(true)
    expect(config.vms.count).to eql(5)
  end

  describe :defaults do
    it 'hard limit is 3000' do
      expect(config.timeouts.hard_limit).to eq(3000)
    end

    it 'queue defaults to builds.linux' do
      expect(config.queue).to eq('builds.linux')
    end

    it 'vms.count defaults to 1' do
      expect(config.vms.count).to eq(1)
    end

    it 'vms.names defaults to [travis-env-1]' do
      Travis::Worker.config.env = 'test' # hrmm
      config.vms.count = 2
      expect(config.vms.names).to eq(%w(travis-test-1 travis-test-2))
    end
  end

  describe 'set' do
    it 'sets a value to a dot-separated path' do
      config.set('foo.bar', 'baz' => 'buz')
      expect(config.foo.bar.baz).to eq('buz')
    end
  end
end
