require 'test_helper'

class JobConfigTest < Test::Unit::TestCase
  include Travis

  Job::Config.send :public, *Job::Config.protected_instance_methods

  attr_reader :config, :shell

  def setup
    super

    @shell = Worker.shell = Object.new
    shell.stubs(:execute)

    @config = Job::Config.new(INCOMING_PAYLOADS['config:gem-release'])
  end

  test 'perform: reads and sets config' do
    File.stubs(:read).returns("---\n  script: rake ci")
    config.perform
    assert_equal({ 'script' => 'rake ci' }, config.config)
  end
end

