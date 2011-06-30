require 'test_helper'

class WorkerConfigTest < Test::Unit::TestCase
  include Travis::Worker

  Config.send :public, *Config.protected_instance_methods

  attr_reader :config

  def setup
    super
    Config.any_instance.stubs(:load).returns({})
    File.stubs(:exists?).returns(false)

    @config = Config.new
  end

  test 'looks for a file ./.travis.yml' do
    filename = File.expand_path('.travis.yml', '.')
    File.stubs(:exists?).with(filename).returns(true)
    assert_equal filename, config.filename
  end

  test 'looks for a file ~/.travis.yml' do
    filename = File.expand_path('.travis.yml', '~')
    File.stubs(:exists?).with(filename).returns(true)
    assert_equal filename, config.filename
  end

  test 'looks for a file ./travis.yml' do
    filename = File.expand_path('.travis.yml', '/etc')
    File.stubs(:exists?).with(filename).returns(true)
    assert_equal filename, config.filename
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
end
