require 'test_helper'
require 'hashr'

class ReporterHttpBuildTest < Test::Unit::TestCase
  include Travis::Worker

  attr_reader :job, :reporter, :now

  def setup
    super

    Config.any_instance.stubs(:read).returns({})
    Travis::Worker.stubs(:name).returns('the_worker')

    @job = Job::Build.new(Hashr.new(INCOMING_PAYLOADS['build:gem-release']))
    class << job
      def build!
        update(:log => 'log')
        true
      end
    end

    @reporter = Reporter::Http.new(job.build)
    job.observers << reporter

    @now = Time.now
    Time.stubs(:now).returns(now)
  end

  test 'queues a :start message' do
    job.work!
    message = reporter.messages.first
    assert_equal :start, message.type
    assert_equal '/builds/1', message.target
    assert_equal({ :_method => :put, :msg_id => 0, :build => { :started_at => now } }, message.data)
  end

  test 'queues a :log message' do
    job.work!
    message = reporter.messages[2]
    assert_equal :update, message.type
    assert_equal '/builds/1/log', message.target
    assert_equal({ :_method => :put, :msg_id => 2, :build => { :log => 'log' } }, message.data)
  end

  test 'queues a :finished message' do
    job.work!
    message = reporter.messages.last
    log = "Using worker: the_worker\n\nlog\nDone. Build script exited with: 0\n"

    assert_equal :finish, message.type
    assert_equal '/builds/1', message.target
    assert_equal({ :_method => :put, :msg_id => reporter.messages.size - 1, :build => { :finished_at => now, :status => 0, :log => log } }, message.data)
  end
end


