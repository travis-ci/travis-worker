require 'test_helper'

STDOUT.sync = true

class TravisJobStdoutTest < Test::Unit::TestCase
  include Travis

  class StdoutJob < Job::Base
    def perform
      system('echo "some output"')
    end
  end

  attr_reader :now, :job

  def setup
    super
    @now = Time.now
    Time.stubs(:now).returns(now)

    @job = StdoutJob.new(INCOMING_PAYLOADS['build:gem-release'])
  end

  test 'pipes the build output to on_log' do
    job.expects(:on_update).with("some output\n")
    job.perform
    sleep(1)
  end
end

