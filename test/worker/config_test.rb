require 'test_helper'

class WorkerConfigTest < Test::Unit::TestCase
  include Travis

  Worker::Config.send :public, *Worker::Config.protected_instance_methods

  attr_reader :config

  def setup
    super
    Worker::Config.any_instance.stubs(:load).returns({})
    File.stubs(:exists?).returns(false)

    @config = Worker::Config
  end

  test 'looks for a file ./.travis.yml' do
    filename = File.expand_path('.travis.yml', '.')
    File.stubs(:exists?).with(filename).returns(true)
    assert_equal filename, config.new.filename
  end

  test 'looks for a file ~/.travis.yml' do
    filename = File.expand_path('.travis.yml', '~')
    File.stubs(:exists?).with(filename).returns(true)
    assert_equal filename, config.new.filename
  end

  test 'looks for a file ./travis.yml' do
    filename = File.expand_path('.travis.yml', '/etc')
    File.stubs(:exists?).with(filename).returns(true)
    assert_equal filename, config.new.filename
  end
end
