require 'test_helper'

class WorkerConfigTest < Test::Unit::TestCase
  include Travis::Worker

  Config.send :public, *Config.protected_instance_methods

  def setup
    Config.any_instance.stubs(:read_yml).returns({})
  end

  def config
    File.stubs(:exists?).returns(true)
    @config = Config.new
  end

  test 'looks for a file ./config/worker.yml' do
    File.stubs(:exists?).with('./config/worker.yml').returns(true)
    assert_equal './config/worker.yml', Config.new.path
  end

  test 'looks for a file ~/.worker.yml' do
    File.stubs(:exists?).with('./config/worker.yml').returns(false)
    File.stubs(:exists?).with('~/.worker.yml').returns(true)
    assert_equal '~/.worker.yml', Config.new.path
  end

  test 'reads ./config/worker.yml first, ./config/worker.[env].yml second and merges them' do
    File.stubs(:exists?).returns(true)
    File.stubs(:exists?).with('./config/worker.yml').returns(true)

    Config.any_instance.stubs(:read_yml).with('./config/worker.yml').returns('env' => 'staging')
    Config.any_instance.stubs(:read_yml).with('./config/worker.staging.yml').returns('foo' => 'foo')

    assert_equal 'staging', Config.new.read['env']
    assert_equal 'foo', Config.new.read['foo']
  end

  test 'before_script timeout defaults to 120' do
    assert_equal 120, config.timeouts.before_script
  end

  test 'after_script timeout defaults to 120' do
    assert_equal 120, config.timeouts.after_script
  end

  test 'script timeout defaults to 600' do
    assert_equal 600, config.timeouts.script
  end

  test 'bundle timeout defaults to 300' do
    assert_equal 300, config.timeouts.bundle
  end

  test 'queue defaults to builds' do
    assert_equal 'builds', config.queue
  end

  test 'vms.count defaults to 1' do
    assert_equal 1, config.vms.count
  end

  test 'vms.names defaults to [base, worker-1]' do
    assert_equal %w(base worker-1), config.vms.names
  end

  test 'vms.recipes? defaults to false' do
    assert_equal false, config.vms.recipes?
  end

end
