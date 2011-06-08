require 'test_helper'

class JobConfigTest < Test::Unit::TestCase
  include Travis::Job

  Config.send :public, *Config.protected_instance_methods

  attr_reader :config, :shell

  def setup
    super

    @shell = Travis::Worker.shell = Object.new
    shell.stubs(:execute)

    @config = Config.new(INCOMING_PAYLOADS['config:gem-release'])
  end

  test 'perform: changes to the build directory' do
    File.stubs(:read).returns("---\n  script: rake ci")
    assert_equal({ :config => { 'script' => 'rake ci' } }, config.perform)
  end
end

